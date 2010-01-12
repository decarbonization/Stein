//
//  STEvaluator.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STEvaluator.h"
#import "STEvaluatorInternal.h"

#import "STParser.h"

#import "STSymbol.h"
#import "STList.h"
#import "STStringWithCode.h"

#import "STFunction.h"
#import "STClosure.h"
#import "STMessageBridge.h"

#import "STBuiltInFunctions.h"
#import "STEnumerable.h"

#import "NSObject+Stein.h"

NSString *const kSTEvaluatorEnclosingScopeKey = @"\\__enclosingScope";
NSString *const kSTEvaluatorSuperclassKey = @"\\__superclass";
NSString *const kSTBundleIsPureSteinKey = @"STBundleIsPureStein";

#pragma mark Tools

static id CreateClosureForDoList(STEvaluator *self, STList *doList, NSMutableDictionary *scope)
{
	STList *arguments = nil;
	STList *implementation = nil;
	
	id head = [doList head];
	if([head isKindOfClass:[STList class]] && [[head head] isEqualTo:@":"])
	{
		arguments = [head tail];
		[arguments replaceValuesByPerformingSelectorOnEachObject:@selector(string)];
		
		implementation = [doList tail];
	}
	else
	{
		arguments = [STList list];
		implementation = doList;
	}
	
	implementation.isDoConstruct = NO;
	implementation.isQuoted = NO;
	
	return [[[STClosure alloc] initWithPrototype:arguments 
							   forImplementation:implementation 
								   withSignature:nil 
								   fromEvaluator:self 
										 inScope:scope] autorelease];
}

#pragma mark -
#pragma mark Environment Built Ins

STBuiltInFunctionDefine(Import, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	BOOL success = YES;
	for (NSString *argument in arguments)
	{
		success = success && [evaluator import:argument];
	}
	
	return [NSNumber numberWithBool:success];
});

STBuiltInFunctionDefine(Let, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSUInteger numberOfArguments = [arguments count];
	if(numberOfArguments < 1)
		STRaiseIssue(arguments.creationLocation, @"let statement expected identifier, and didn't get one.");
	
	NSString *name = [[arguments objectAtIndex:0] string];
	if(numberOfArguments == 1)
	{
		[evaluator setObject:nil forVariableNamed:name inScope:scope];
	}
	else if(numberOfArguments >= 3)
	{
		STSymbol *directive = [arguments objectAtIndex:1];
		if([directive isEqualTo:@"="])
		{
			id value = __STEvaluateExpression(evaluator, [arguments sublistFromIndex:2], scope);
			[evaluator setObject:value forVariableNamed:name inScope:scope];
			return value;
		}
		else if([directive isEqualTo:@"extend"])
		{
			NSCAssert((numberOfArguments == 4), 
					  @"Expected exactly 4 arguments for class declaration, got %ld.", numberOfArguments);
			
			Class superclass = __STEvaluateExpression(evaluator, [arguments objectAtIndex:2], scope);
			STList *declarations = [arguments objectAtIndex:3];
			
			return STDefineClass(name, superclass, declarations);
		}
		else
		{
			STRaiseIssue(arguments.creationLocation, @"Malformed let statement, directive {%@} is undefined.", [directive string]);
		}
	}
	
	return STNull;
});

#pragma mark -

STBuiltInFunctionDefine(Function, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	if([arguments count] < 3)
		STRaiseIssue(arguments.creationLocation, @"function requires 3 arguments, was given %ld.", [arguments count]);
	
	NSString *signature = nil;
	STList *parameterList = nil;
	STList *implementation = nil;
	
	id firstValueInDefinition = [arguments objectAtIndex:1];
	if([firstValueInDefinition isKindOfClass:[NSString class]])
	{
		signature = firstValueInDefinition;
		parameterList = [arguments objectAtIndex:2];
		implementation = [STList listWithList:[arguments objectAtIndex:3]];
	}
	else
	{
		parameterList = firstValueInDefinition;
		implementation = [STList listWithList:[arguments objectAtIndex:2]];
		
		NSMutableString *signatureInProgress = [NSMutableString stringWithString:@"@"];
		for (NSUInteger index = 0; index < [parameterList count]; index++)
			[signatureInProgress appendString:@"@"];
		
		signature = signatureInProgress;
	}
	[parameterList replaceValuesByPerformingSelectorOnEachObject:@selector(string)];
	implementation.isQuoted = NO;
	
	STClosure *closure = [[[STClosure alloc] initWithPrototype:parameterList
											 forImplementation:implementation
												 withSignature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]
												 fromEvaluator:evaluator 
													   inScope:scope] autorelease];
	NSString *functionName = [[arguments objectAtIndex:0] string];
	[scope setObject:closure forKey:functionName];
	
	closure.name = functionName;
	
	return closure;
});

#pragma mark -
#pragma mark Messaging Built Ins

STBuiltInFunctionDefine(SendMessage, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	if([arguments count] < 1)
		STRaiseIssue(arguments.creationLocation, @"# expected function or complete message, neither was provided.");
	
	id target = __STEvaluateExpression(evaluator, [arguments head], scope);
	if([arguments count] == 1)
		return target;
	
	SEL selector = NULL;
	NSArray *argumentsArray = nil;
	MessageListGetSelectorAndArguments(evaluator, scope, [arguments tail], &selector, &argumentsArray);
	
	return STMessageBridgeSend(target, selector, argumentsArray);
});

STBuiltInFunctionDefine(Super, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id target = [scope objectForKey:@"self"];
	Class superclass = [scope objectForKey:kSTEvaluatorSuperclassKey];
	
	NSMutableString *selectorString = [NSMutableString string];
	NSMutableArray *evaluatedArguments = [NSMutableArray array];
	
	NSUInteger index = 0;
	for (id expression in arguments)
	{
		//If it's even, it's part of the selector
		if((index % 2) == 0)
			[selectorString appendString:[expression string]];
		else
			[evaluatedArguments addObject:__STEvaluateExpression(evaluator, expression, scope)];
		
		index++;
	}
	
	return STMessageBridgeSendSuper(target, superclass, NSSelectorFromString(selectorString), evaluatedArguments);
});

#pragma mark -

@implementation STEvaluator

#pragma mark Destruction

- (void)dealloc
{
	[mRootScope release];
	mRootScope = nil;
	
	[mSearchPaths release];
	mSearchPaths = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if((self = [super init]))
	{
		//Setup the root scope, and expose our built in functions and constants.
		mRootScope = [NSMutableDictionary new];
		
		//Built in Math Functions
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Add, self) forKey:@"+"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Subtract, self) forKey:@"-"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Multiply, self) forKey:@"*"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Divide, self) forKey:@"/"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Modulo, self) forKey:@"%"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Power, self) forKey:@"**"];
		
		//Built in Comparison Functions
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Equal, self) forKey:@"="];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(NotEqual, self) forKey:@"≠"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(LessThan, self) forKey:@"<"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(LessThanOrEqual, self) forKey:@"≤"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThan, self) forKey:@">"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThanOrEqual, self) forKey:@"≥"];
		
		//Built in Boolean Operators
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Or, self) forKey:@"or"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(And, self) forKey:@"and"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Not, self) forKey:@"not"];
		
		//Core Built ins
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Let, self) forKey:@"let"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Function, self) forKey:@"function"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(SendMessage, self) forKey:@"#"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Super, self) forKey:@"super"];
		
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Break, self) forKey:@"break"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Continue, self) forKey:@"continue"];
		
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Import, self) forKey:@"import"];
		
		//Bridging
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(BridgeFunction, self) forKey:@"bridge-function"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(BridgeConstant, self) forKey:@"bridge-constant"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(MakeObjectReference, self) forKey:@"ref"];
		
		//Collection creation
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Array, self) forKey:@"array"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(List, self) forKey:@"list"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Dictionary, self) forKey:@"dict"];
		
		//Constants
		[mRootScope setObject:STTrue forKey:@"true"];
		[mRootScope setObject:STFalse forKey:@"false"];
		[mRootScope setObject:STNull forKey:@"null"];
		
		//Globals
		[mRootScope setObject:[[NSProcessInfo processInfo] arguments] forKey:@"Args"];
		[mRootScope setObject:[[NSProcessInfo processInfo] environment] forKey:@"Env"];
		
		
		//Load and run the Prelude file.
		NSBundle *evaluatorBundle = [NSBundle bundleForClass:[self class]];
		NSURL *preludeLocation = [evaluatorBundle URLForResource:@"Prelude" withExtension:@"st"];
		if(preludeLocation)
		{
			NSError *error = nil;
			NSString *preludeSource = [NSString stringWithContentsOfURL:preludeLocation encoding:NSUTF8StringEncoding error:&error];
			if(preludeSource)
			{
				@try
				{
					[self parseAndEvaluateString:preludeSource];
				}
				@catch (NSException *e)
				{
					fprintf(stderr, "*** STEvaluator could not load Prelude, got error {%s}.\n", [[e reason] UTF8String]);
				}
			}
			else
			{
				fprintf(stderr, "*** STEvaluator could not load Prelude, got error {%s}.\n", [[error localizedDescription] UTF8String]);
			}
		}
		else
		{
			fprintf(stderr, "*** STEvaluator could not find Prelude, continuing without it.\n");
		}
		
		mSearchPaths = [[NSMutableArray alloc] initWithObjects:
						@"/", 
						[evaluatorBundle resourcePath], 
						[evaluatorBundle sharedFrameworksPath], 
						[evaluatorBundle privateFrameworksPath], 
						[[NSFileManager defaultManager] currentDirectoryPath], 
						@"/Library/Frameworks",
						@"/System/Library/Frameworks",
						[@"~/Library/Frameworks" stringByExpandingTildeInPath],
						nil];
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Scoping

- (NSMutableDictionary *)scopeWithEnclosingScope:(NSMutableDictionary *)enclosingScope
{
	NSMutableDictionary *scope = [NSMutableDictionary dictionaryWithCapacity:1];
	if(enclosingScope)
		[scope setObject:enclosingScope forKey:kSTEvaluatorEnclosingScopeKey];
	else
		[scope setObject:mRootScope forKey:kSTEvaluatorEnclosingScopeKey];
	
	return scope;
}

#pragma mark -

NSMutableDictionary *LastScopeWithVariableNamed(NSMutableDictionary *currentScope, NSString *name)
{
	while (currentScope != nil)
	{
		if([[currentScope allKeys] containsObject:name])
			return currentScope;
		
		currentScope = [currentScope objectForKey:kSTEvaluatorEnclosingScopeKey];
	}
	
	return nil;
}

- (void)setObject:(id)object forVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope
{
	if([name isEqualToString:@"_here"] || [name isEqualToString:@"_interpreter"])
		[NSException raise:NSInternalInconsistencyException 
					format:@"You cannot set the variable %@, it is read only.", name];
	
	
	unichar firstCharacterInName = [name characterAtIndex:0];
	if(firstCharacterInName == '$')
	{
		if(object)
			[mRootScope setObject:object forKey:[name substringFromIndex:1]];
		else
			[mRootScope removeObjectForKey:[name substringFromIndex:1]];
	}
	else if(firstCharacterInName == '@')
	{
		id target = [self objectForVariableNamed:@"self" inScope:scope];
		[target setValue:object forIvarNamed:[name substringFromIndex:1]];
	}
	else
	{
		NSMutableDictionary *targetScope = LastScopeWithVariableNamed(scope, name);
		if(!targetScope)
			targetScope = scope;
		
		if(object)
			[targetScope setObject:object forKey:name];
		else
			[targetScope removeObjectForKey:name];
	}
}

- (id)objectForVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope
{
	if([name isEqualToString:@"_here"])
		return scope;
	else if([name isEqualToString:@"_evaluator"])
		return self;
	
	
	unichar firstCharacterInName = [name characterAtIndex:0];
	if(firstCharacterInName == '$')
	{
		return [mRootScope objectForKey:[name substringFromIndex:1]];
	}
	else if(firstCharacterInName == '@')
	{
		id target = [self objectForVariableNamed:@"self" inScope:scope];
		return [target valueForIvarNamed:[name substringFromIndex:1]];
	}
	
	
	NSMutableDictionary *targetScope = LastScopeWithVariableNamed(scope, name);
	if(targetScope)
	{
		id value = [targetScope objectForKey:name];
		if(value)
			return value;
	}
	
	
	Class class = NSClassFromString(name);
	NSAssert((class != nil), @"Could not find a value for the variable '%@'.", name);
	
	return class;
}

#pragma mark -

@synthesize rootScope = mRootScope;

#pragma mark -
#pragma mark Parsing

- (NSArray *)parseString:(NSString *)string
{
	return STParseString(string, self);
}

#pragma mark -
#pragma mark Evaluation

id __STEvaluateList(STEvaluator *self, STList *list, NSMutableDictionary *scope)
{
	if(list.isDoConstruct)
		return CreateClosureForDoList(self, list, scope);
	
	if(list.isQuoted)
		return list;
	
	if([list count] == 0)
		return STNull;
	
	id target = __STEvaluateExpression(self, [list head], scope);
	
	if([target respondsToSelector:@selector(applyWithArguments:inScope:)])
	{
		NSObject < STFunction > *function = target;
		if([function evaluatesOwnArguments])
			return [function applyWithArguments:[list tail] inScope:scope];
		
		STList *evaluatedArguments = [STList list];
		for (id expression in [list tail])
		{
			id evaluateArgument = __STEvaluateExpression(self, expression, scope);
			[evaluatedArguments addObject:evaluateArgument];
		}
		
		return [function applyWithArguments:evaluatedArguments inScope:scope];
	}
	
	if([list count] == 1)
		return target;
	
	SEL selector = NULL;
	NSArray *arguments = nil;
	MessageListGetSelectorAndArguments(self, scope, [list tail], &selector, &arguments);
	
	return STMessageBridgeSend(target, selector, arguments);
}

#pragma mark -

id __STEvaluateExpression(STEvaluator *self, id expression, NSMutableDictionary *scope)
{
	if([expression isKindOfClass:[NSArray class]])
	{
		id lastResult = nil;
		for (id subexpression in expression)
			lastResult = __STEvaluateExpression(self, subexpression, scope);
		
		return lastResult;
	}
	else if([expression isKindOfClass:[STList class]])
	{
		return __STEvaluateList(self, expression, scope);
	}
	else if([expression isKindOfClass:[STSymbol class]])
	{
		if([expression isQuoted])
			return expression;
		
		return [self objectForVariableNamed:[expression string] inScope:scope] ?: STNull;
	}
	else if([expression isKindOfClass:[STStringWithCode class]])
	{
		return [expression applyWithEvaluator:self scope:scope];
	}
	
	return expression;
}

- (id)evaluateExpression:(id)expression inScope:(NSMutableDictionary *)scope
{
	if(!scope)
		scope = mRootScope;
	
	return __STEvaluateExpression(self, expression, scope);
}

#pragma mark -

- (id)parseAndEvaluateString:(NSString *)string
{
	return [self evaluateExpression:[self parseString:string] inScope:mRootScope];
}

#pragma mark -
#pragma mark Importing

@synthesize searchPaths = mSearchPaths;

#pragma mark -

- (void)addSearchPath:(NSString *)searchPath
{
	NSParameterAssert(searchPath);
	
	if(![mSearchPaths containsObject:searchPath])
		[mSearchPaths addObject:searchPath];
}

- (void)removeSearchPath:(NSString *)searchPath
{
	NSParameterAssert(searchPath);
	
	if([mSearchPaths containsObject:searchPath])
		[mSearchPaths removeObject:searchPath];
}

#pragma mark -

- (BOOL)_importFileAtPath:(NSString *)location
{
	NSError *error = nil;
	NSString *fileContents = [NSString stringWithContentsOfFile:location encoding:NSUTF8StringEncoding error:&error];
	if(!fileContents)
	{
		fprintf(stderr, "Could not load file at location «%s». Error {%s}.\n", [location UTF8String], [[error description] UTF8String]);
		return NO;
	}
	
	[self parseAndEvaluateString:fileContents];
	
	return YES;
}

- (BOOL)_importBundleAtPath:(NSString *)location
{
	NSBundle *bundle = [NSBundle bundleWithPath:location];
	if(!bundle)
		return NO;
	
	if(![[bundle objectForInfoDictionaryKey:kSTBundleIsPureSteinKey] boolValue])
	{
		if(![bundle load])
			return NO;
	}
	
	NSString *preludeLocation = [bundle pathForResource:@"Prelude" ofType:@"st"];
	if(preludeLocation)
		return [self _importFileAtPath:preludeLocation];
	
	return YES;
}

- (BOOL)import:(NSString *)location
{
	if(!location)
		return NO;
	
	BOOL isDirectory = NO;
	for (NSString *searchPath in mSearchPaths)
	{
		NSString *fullPath = [searchPath stringByAppendingPathComponent:location];
		if([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory])
		{
			if(isDirectory)
				return [self _importBundleAtPath:fullPath];
			else
				return [self _importFileAtPath:fullPath];
		}
	}
	
	return NO;
}

@end
