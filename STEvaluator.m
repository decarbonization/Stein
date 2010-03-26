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
#import "STObjectBridge.h"

#import "STBuiltInFunctions.h"
#import "STEnumerable.h"

#import "NSObject+Stein.h"

#import <readline/readline.h> //For STRunREPL()

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
		implementation = [STList listWithList:doList];
	}
	
	implementation.isDoConstruct = NO;
	implementation.isQuoted = NO;
	
	return [[STClosure alloc] initWithPrototype:arguments 
							  forImplementation:implementation 
								  fromEvaluator:self 
										inScope:scope];
}

#pragma mark -
#pragma mark Environment Built Ins

STBuiltInFunctionDefine(Import, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	for (NSString *argument in arguments)
	{
		if(![evaluator import:argument])
			STRaiseIssue(arguments.creationLocation, @"Could not import '%@'.", argument);
	}
	
	return STTrue;
});

STBuiltInFunctionDefine(Let, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSUInteger numberOfArguments = [arguments count];
	if(numberOfArguments < 1)
		STRaiseIssue(arguments.creationLocation, @"let statement expected identifier, and didn't get one.");
	
	STSymbol *name = [arguments objectAtIndex:0];
	if(numberOfArguments == 1)
	{
		[evaluator setObject:nil forVariableNamed:name inScope:scope];
	}
	else if(numberOfArguments >= 3)
	{
		STSymbol *directive = [arguments objectAtIndex:1];
		if([directive isEqualTo:@"="])
		{
			id expression = [arguments sublistFromIndex:2];
			if([expression count] == 1 && 
			   [[expression head] isKindOfClass:[STList class]] && 
			   [[expression head] isDoConstruct])
			{
				expression = [expression head];
			}
			
			id value = __STEvaluateExpression(evaluator, expression, scope);
			[evaluator setObject:value forVariableNamed:name inScope:scope];
			return value;
		}
		else if([directive isEqualTo:@"extend"])
		{
			NSCAssert((numberOfArguments == 4), 
					  @"Expected exactly 4 arguments for class declaration, got %ld.", numberOfArguments);
			
			Class superclass = __STEvaluateExpression(evaluator, [arguments objectAtIndex:2], scope);
			STList *declarations = [arguments objectAtIndex:3];
			
			return STDefineClass(name.string, superclass, declarations, evaluator);
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
	
	STList *parameterList = [arguments objectAtIndex:1];
	STList *implementation = [STList listWithList:[arguments objectAtIndex:2]];
		
	[parameterList replaceValuesByPerformingSelectorOnEachObject:@selector(string)];
	implementation.isQuoted = NO;
	
	STClosure *closure = [[STClosure alloc] initWithPrototype:parameterList
											forImplementation:implementation
												fromEvaluator:evaluator 
													  inScope:scope];
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
	
	return STObjectBridgeSend(target, selector, argumentsArray, evaluator);
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
	
	return STObjectBridgeSendSuper(target, superclass, NSSelectorFromString(selectorString), evaluatedArguments, evaluator);
});

#pragma mark -

@implementation STEvaluator

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
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Equal, self) forKey:@"=="];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(NotEqual, self) forKey:@"!="];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(LessThan, self) forKey:@"<"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(LessThanOrEqual, self) forKey:@"<="];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThan, self) forKey:@">"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThanOrEqual, self) forKey:@">="];
		
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
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(BridgeExtern, self) forKey:@"extern"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(MakeObjectReference, self) forKey:@"ref"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(FunctionWrapper, self) forKey:@"function-wrapper"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(WrapBlock, self) forKey:@"wrap-block"];
		
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
						[[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] stringByDeletingLastPathComponent],
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

- (void)setObject:(id)object forVariableNamed:(STSymbol *)name inScope:(NSMutableDictionary *)scope
{
	if([name isEqualToString:@"_here"] || [name isEqualToString:@"_interpreter"])
		STRaiseIssue(name.creationLocation, @"Attempting to set readonly variable '%@'.", [name prettyDescription]);
	
	NSString *nameString = name.string;
	unichar firstCharacterInName = [nameString characterAtIndex:0];
	if(firstCharacterInName == '$')
	{
		if(object)
			[mRootScope setObject:object forKey:[nameString substringFromIndex:1]];
		else
			[mRootScope removeObjectForKey:[nameString substringFromIndex:1]];
	}
	else if(firstCharacterInName == '@')
	{
		id target = nil;
		@try
		{
			target = [self objectForVariableNamed:ST_SYM(@"self") inScope:scope];
		}
		@catch (NSException *e)
		{
			if([[e name] isEqualToString:SteinException])
			{
				STRaiseIssue(name.creationLocation, @"Attempting to set instance variable %@ outside of class.", [name prettyDescription]);
			}
			else
			{
				@throw;
			}
		}
		
		[target setValue:object forIvarNamed:[nameString substringFromIndex:1]];
	}
	else
	{
		NSMutableDictionary *targetScope = LastScopeWithVariableNamed(scope, nameString);
		if(!targetScope)
			targetScope = scope;
		
		if(object)
			[targetScope setObject:object forKey:nameString];
		else
			[targetScope removeObjectForKey:nameString];
	}
}

- (id)objectForVariableNamed:(STSymbol *)name inScope:(NSMutableDictionary *)scope
{
	if([name isEqualToString:@"_here"])
		return scope;
	else if([name isEqualToString:@"_evaluator"])
		return self;
	
	
	NSString *nameString = name.string;
	unichar firstCharacterInName = [nameString characterAtIndex:0];
	if(firstCharacterInName == '$')
	{
		return [mRootScope objectForKey:[nameString substringFromIndex:1]];
	}
	else if(firstCharacterInName == '@')
	{
		id target = nil;
		@try
		{
			target = [self objectForVariableNamed:ST_SYM(@"self") inScope:scope];
		}
		@catch (NSException *e)
		{
			if([[e name] isEqualToString:SteinException])
			{
				STRaiseIssue(name.creationLocation, @"Attempting to accces instance variable %@ outside of class.", [name prettyDescription]);
			}
			else
			{
				@throw;
			}
		}
		
		return [target valueForIvarNamed:[nameString substringFromIndex:1]];
	}
	
	
	NSMutableDictionary *targetScope = LastScopeWithVariableNamed(scope, nameString);
	if(targetScope)
	{
		id value = [targetScope objectForKey:nameString];
		if(value)
			return value;
	}
	
	
	Class class = NSClassFromString(nameString);
	if(!class)
		STRaiseIssue(name.creationLocation, @"Could not find a value for '%@'.", [name prettyDescription]);
	
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
		
		return STFunctionApplyWithEvaluator(function, evaluatedArguments, self);
	}
	
	if([list count] == 1)
		return target;
	
	SEL selector = NULL;
	NSArray *arguments = nil;
	MessageListGetSelectorAndArguments(self, scope, [list tail], &selector, &arguments);
	
	return STObjectBridgeSend(target, selector, arguments, self);
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
		
		return [self objectForVariableNamed:expression inScope:scope] ?: STNull;
	}
	else if([expression isKindOfClass:[STStringWithCode class]])
	{
		return [expression applyWithEvaluator:self scope:scope];
	}
	else if([expression isKindOfClass:[NSString class]])
	{
		return [expression copy];
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
	NSString *const possibleExtensions[] = {
		nil,
		@"st",
		@"framework",
		@"bundle",
	};
	
	if(!location)
		return NO;
	
	BOOL isDirectory = NO;
	for (NSString *searchPath in mSearchPaths)
	{
		NSString *fullPath = [searchPath stringByAppendingPathComponent:location];
		for (NSUInteger index = 0; index < (sizeof possibleExtensions / sizeof possibleExtensions[0]); index++)
		{
			NSString *extension = possibleExtensions[index];
			if(extension)
				fullPath = [fullPath stringByAppendingPathExtension:extension];
			
			if([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory])
			{
				if(isDirectory)
					return [self _importBundleAtPath:fullPath];
				else
					return [self _importFileAtPath:fullPath];
			}
		}
	}
	
	return NO;
}

@end

#pragma mark -

int STMain(int argc, const char *argv[], NSString *filename)
{
	NSCParameterAssert(filename);
	
	NSURL *mainFile = [[NSBundle mainBundle] URLForResource:filename withExtension:@"st"];
	NSCAssert((mainFile != nil), @"Could not find file %@ in main bundle.", filename);
	
	NSError *error = nil;
	NSString *source = [NSString stringWithContentsOfURL:mainFile encoding:NSUTF8StringEncoding error:&error];
	NSCAssert((source != nil), @"Could not load file %@ in main bundle. Error {%@}.", filename, error);
	
	STEvaluator *evaluator = [STEvaluator new];
	id result = [evaluator parseAndEvaluateString:source];
	if(!result)
		return EXIT_SUCCESS;
	
	return [result intValue];
}

/*!
 @function
 @abstract		Analyze a string read from the REPL, and indicate the number of unbalanced parentheses and unbalanced brackets found.
 @param			numberOfUnbalancedParentheses	On return, an integer describing the number of unbalanced parentheses in the specified string.
 @param			numberOfUnbalancedBrackets		On return, an integer describing the number of unbalanced brackets in the specified string.
 @param			string							The string to analyze.
 @discussion	All parameters are required.
 */
static void FindUnbalancedExpressions(NSInteger *numberOfUnbalancedParentheses, NSInteger *numberOfUnbalancedBrackets, NSString *string)
{
	NSCParameterAssert(numberOfUnbalancedParentheses);
	NSCParameterAssert(numberOfUnbalancedBrackets);
	NSCParameterAssert(string);
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = 0; index < stringLength; index++)
	{
		switch ([string characterAtIndex:index])
		{
			case '(':
				(*numberOfUnbalancedParentheses)++;
				break;
				
			case ')':
				(*numberOfUnbalancedParentheses)--;
				break;
				
			case '[':
				(*numberOfUnbalancedBrackets)++;
				break;
				
			case ']':
				(*numberOfUnbalancedBrackets)--;
				break;
				
			default:
				break;
		}
	}
}

void STRunREPL()
{
	//Initialize readline so we get history.
	rl_initialize();
	
	//Create an evaluator.
	STEvaluator *evaluator = [STEvaluator new];
	
	printf("stein ready [version %s]\n", [[SteinBundle() objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String]);
	for (;;)
	{
		//Break away if we've been told to quit|exit|EOF.
		char *rawLine = readline("Stein> ");
		if(!rawLine || (strlen(rawLine) == 0) || (strcmp(rawLine, "quit") == 0) || (strcmp(rawLine, "exit") == 0))
		{
			free(rawLine);
			fprintf(stdout, "goodbye\n");
			break;
		}
		
		@try
		{
			//Convert the line we just read into an NSString and free it. We use a mutable
			//string so we can append at a later time for the case of partial lines.
			NSMutableString *line = [NSMutableString stringWithUTF8String:rawLine];
			
			
			//Handle unbalanced pairs of parentheses and brackets.
			NSInteger numberOfUnbalancedParentheses = 0, numberOfUnbalancedBrackets = 0;
			FindUnbalancedExpressions(&numberOfUnbalancedParentheses, &numberOfUnbalancedBrackets, line);
			
			while (numberOfUnbalancedParentheses > 0)
			{
				char *partialLine = readline("... ");
				
				for (int i = 0; i < strlen(partialLine); i++)
				{
					if(partialLine[i] == '(')
						numberOfUnbalancedParentheses++;
					else if(partialLine[i] == ')')
						numberOfUnbalancedParentheses--;
				}
				
				[line appendFormat:@"%s", partialLine];
				free(partialLine);
			}
			
			while (numberOfUnbalancedBrackets > 0)
			{
				char *partialLine = readline("... ");
				
				for (int i = 0; i < strlen(partialLine); i++)
				{
					if(partialLine[i] == '[')
						numberOfUnbalancedBrackets++;
					else if(partialLine[i] == ']')
						numberOfUnbalancedBrackets--;
				}
				
				[line appendFormat:@"%s", partialLine];
				free(partialLine);
			}
			
			
			//Parse and evaluate the data we just read in from the user, and print out the result.
			id result = [evaluator parseAndEvaluateString:line];
			fprintf(stdout, "=> %s\n", [[result prettyDescription] UTF8String]);
		}
		@catch (NSException *e)
		{
			fprintf(stderr, "Error: %s\n", [[e reason] UTF8String]);
		}
		@finally
		{
			free(rawLine);
		}
	}
}
