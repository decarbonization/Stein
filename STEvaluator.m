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

NSString *const kSTEvaluatorEnclosingScopeKey = @"$__enclosingScope";
NSString *const kSTEvaluatorSuperclassKey = @"$__superclass";

#pragma mark -
#pragma mark Environment Built Ins

STBuiltInFunctionDefine(Let, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSUInteger numberOfArguments = [arguments count];
	NSCAssert(numberOfArguments >= 1, 
			  @"Expected at least one argument for let statement, got 0.");
	
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
			NSCAssert(0, @"let statement does not understand what the %@ directive means.", directive);
		}
	}
	
	return STNull;
});

#pragma mark -

STBuiltInFunctionDefine(Function, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSCAssert(([arguments count] >= 3), 
			  @"Wrong number of arguments given to lambda, expected at least 3, got %ld.", [arguments count]);
	
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
	NSCAssert([arguments count] >= 1, @"# expected at least 1 argument, got 0.");
	
	id target = __STEvaluateExpression(evaluator, [arguments head], scope);
	if([arguments count] == 1)
		return target;
	
	return __STSendMessageWithTargetAndArguments(evaluator, target, [arguments tail], scope);
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
		
		
		//Load and run the Prelude file.
		NSURL *preludeLocation = [[NSBundle bundleForClass:[self class]] URLForResource:@"Prelude" withExtension:@"st"];
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
			[mRootScope setObject:object forKey:name];
		else
			[mRootScope removeObjectForKey:name];
	}
	else if(firstCharacterInName == '@')
	{
		id target = [self objectForVariableNamed:@"self" inScope:scope];
		[target setValue:object forIvarNamed:name];
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
		return [mRootScope objectForKey:name];
	}
	else if(firstCharacterInName == '@')
	{
		id target = [self objectForVariableNamed:@"self" inScope:scope];
		return [target valueForIvarNamed:name];
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

id __STSendMessageWithTargetAndArguments(STEvaluator *self, id target, STList *arguments, NSMutableDictionary *scope)
{
	NSMutableString *selectorString = [NSMutableString string];
	NSMutableArray *evaluatedArguments = [NSMutableArray array];
	
	NSUInteger index = 0;
	for (id expression in arguments)
	{
		//If it's even, it's part of the selector
		if((index % 2) == 0)
			[selectorString appendString:[expression string]];
		else
			[evaluatedArguments addObject:__STEvaluateExpression(self, expression, scope)];
		
		index++;
	}
	
	return STMessageBridgeSend(target, NSSelectorFromString(selectorString), evaluatedArguments);
}

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
	
	return __STSendMessageWithTargetAndArguments(self, target, [list tail], scope);
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

@end
