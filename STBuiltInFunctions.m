//
//  STBuiltInFunctions.m
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STBuiltInFunctions.h"

#import "STObjectBridge.h"
#import "STTypeBridge.h"
#import "STBridgedFunction.h"
#import "NSObject+SteinInternalSupport.h"

#import "STNativeFunctionWrapper.h"
#import "STTypeBridge.h"
#import "STStructClasses.h"
#import "STPointer.h"
#import <dlfcn.h>
#import <objc/message.h>

#import "STParser.h"
#import "STList.h"
#import "STSymbol.h"

#import "STInterpreter.h"
#import "STScope.h"
#import "STModule.h"

//-
//	typedef		STBuiltInFunctionImplementation
//	purpose		To describe the form Stein's core library's native functions must take.
//-
typedef id(*STBuiltInFunctionImplementation)(STList *arguments, STScope *scope);

//-
//	class		STBuiltInFunction
//	purpose		To provide an STFunction-implementing object that calls into native \
//				functions allowing Stein's core library to be as speedy as possible.
//-
@interface STBuiltInFunction : NSObject <STFunction>
{
	STBuiltInFunctionImplementation mImplementation;
	BOOL mEvaluatesOwnArguments;
}

#pragma mark Initialization

//-
//	method		initWithImplementation:evaluatesOwnArguments:
//	intention	To initialize the receiver with a specified implementation \
//				and whether or not the implementation intends on evaluating its own arguments.
//-
- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments;

#pragma mark - Properties

//-
//	property	implementation
//	description	The native implementation of the STBuiltInFunction.
//	inaccessible
//-
@property (readonly, nonatomic) STBuiltInFunctionImplementation implementation;

@end

#pragma mark -

@implementation STBuiltInFunction

#pragma mark Initialization

- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments
{
	NSParameterAssert(implementation);
	
	if((self = [super init]))
	{
		mImplementation = implementation;
		mEvaluatesOwnArguments = evaluatesOwnArguments;
	}
	
	return self;
}

#pragma mark - Properties

@synthesize evaluatesOwnArguments = mEvaluatesOwnArguments;
@synthesize implementation = mImplementation;

- (STScope *)superscope
{
	return nil;
}

- (NSString *)description
{
	Dl_info info;
	if(dladdr(mImplementation, &info) == 0)
		return [super description];
	
	return [NSString stringWithFormat:@"<native-function:%p @_%s>", self, info.dli_sname ?: "(unknown)"];
}

#pragma mark - Application

- (id)applyWithArguments:(STList *)message inScope:(STScope *)scope
{
	return (*mImplementation)(message, scope) ?: STNull;
}

@end

#pragma mark - Function Implementations

#pragma mark • Core

//-
//	function	let
//	intention	To allow assignment of variables and creation of new classes
//	impure
//	forms {
//		(name = value) -> value \
//			Create a readonly binding from `name` to `value` in the current scope, yielding `value`.
//		(name extend superclass { |SubclassForms| }) -> Class \
//			Create a new class with `name` whose superclass is named `superclass`
//			where the methods described in {} are added to it.
//		(class continues { |SubclassForms| } -> Class \
//			Extend `class` with the methods described in {}.
//	}
//-
static id let(STList *arguments, STScope *scope)
{
	if(arguments.count < 3)
		STRaiseIssue(arguments.creationLocation, @"let requires 3 or more parameters, got %ld.", arguments.count);
	
	NSString *name = [[arguments objectAtIndex:0] string];
	
	STSymbol *directive = [arguments objectAtIndex:1];
	if([directive isEqualTo:@"="])
	{
		id expression = [arguments sublistFromIndex:2];
		id value = STEvaluate(expression, scope);
		[scope setValue:value forConstantNamed:name];
		
		if([value respondsToSelector:@selector(setName:)])
            objc_msgSend(value, @selector(setName:), name);
		
		return value;
	}
	else if([directive isEqualTo:@"extend"])
	{
		if(arguments.count < 4)
			STRaiseIssue(arguments.creationLocation, @"let-extend requires 4 parameters, got %ld", arguments.count);
		
		Class superclass = STEvaluate([arguments objectAtIndex:2], scope);
		STList *declarations = [arguments objectAtIndex:3];
		
		return STDefineClass(name, superclass, declarations, scope);
	}
	else if([directive isEqualTo:@"continue"])
	{
		Class class = STEvaluate([arguments objectAtIndex:0], scope);
		STList *declarations = [arguments objectAtIndex:2];
		STExtendClass(class, declarations);
		return class;
	}
	
	return STNull;
}

//-
//	function	set!
//	intention	To mutate variables in the current scope.
//	impure
//	forms {
//		(name value) -> id \
//			Set the variable `name` to `value`, yielding `value`.
//	}
//-
static id setBang(STList *arguments, STScope *scope)
{
	if(arguments.count != 2)
		STRaiseIssue(arguments.creationLocation, @"set! requires exactly 2 parameters (name, value), got %ld.", arguments.count);
	
	NSString *name = [[arguments objectAtIndex:0] string];
	
	id value = STEvaluate([arguments objectAtIndex:1], scope);
	if([value respondsToSelector:@selector(setName:)])
		objc_msgSend(value, @selector(setName:), name);
	
	[scope setValue:value forKeyPath:name];
	
	return value;
}

//-
//	function	unset!
//	intention	To unset value-bindings in the current scope.
//	impure
//	forms {
//		(name) -> null \
//			Remove any bindings for `name` in the current scope or any scope it inherits from.
//	}
//	note		unset! can be used on readonly value-bindings as well as variables, there is no restriction.
//-
static id unsetBang(STList *arguments, STScope *scope)
{
	if(arguments.count != 1)
		STRaiseIssue(arguments.creationLocation, @"unset! requires exactly 1 parameter (name), got %ld.", arguments.count);
	
	[scope removeValueForVariableNamed:[[arguments objectAtIndex:0] string] searchParentScopes:YES];
	
	return STNull;
}

#pragma mark -

//-
//	function	load
//	intention	To load all given paths.
//	forms {
//		(path...) -> id \
//			If the path is a directory, it is treated like a bundle and loaded with NSBundle, \
//			yielding a boolean indicating whether the load was successful. If the path is a file, \
//			it is treated like a Stein file and loaded, yielding the result of the last expression \
//			of evaluating the file.
//	}
//-
static id load(STList *arguments, STScope *scope)
{
	id lastResult = nil;
	for (NSString *path in arguments)
	{
		BOOL isDirectory = NO;
		if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
			STRaiseIssue(arguments.creationLocation, @"Could not load file at path %@, it does not exist.", path);
		
		if(isDirectory)
		{
			lastResult = [NSNumber numberWithBool:[[NSBundle bundleWithPath:path] load]];
		}
		else
		{
			NSError *error = nil;
			NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
			if(!contents)
				STRaiseIssue(arguments.creationLocation, @"Could not load file at path %@. Got error «%@».", path, [error localizedDescription]);
			
			NSArray *expressions = STParseString(contents, path);
			lastResult = STEvaluate(expressions, scope);
		}
	}
	
	return lastResult;
}

//-
//	function	super
//	intention	To allow access to an object's superclass's methods.
//	forms {
//		(super |Message|) -> id
//	}
//-
static id _super(STList *message, STScope *scope)
{
	if(message.count == 0)
		STRaiseIssue(message.creationLocation, @"super requires a message.");
	
	id self = [scope valueForVariableNamed:@"self" searchParentScopes:YES];
	Class superclass = [scope valueForVariableNamed:kSTSuperclassVariableName searchParentScopes:YES];
	if(!self || !superclass)
		STRaiseIssue(message.creationLocation, @"super called outside of class context.");
	
	NSMutableString *selectorString = [NSMutableString string];
	NSMutableArray *parameters = [NSMutableArray array];
	
	BOOL isLookingForLabel = YES;
	for (id component in message)
	{
		if(isLookingForLabel)
		{
			[selectorString appendString:[component string]];
		}
		else
		{
			[parameters addObject:STEvaluate(component, scope)];
		}
		
		isLookingForLabel = !isLookingForLabel;
	}
	
	return STObjectBridgeSendSuper(self, superclass, NSSelectorFromString(selectorString), parameters, scope);
}

#pragma mark -

//-
//  function    autoreleasepool
//  intention   To encapsulate an area of code in a autorelease pool.
//  forms {
//      (autoreleasepool {function}) -> id
//  }
//-
static id autoreleasepool(STList *arguments, STScope *scope)
{
    if(arguments.count != 1)
		STRaiseIssue(arguments.creationLocation, @"autoreleasepool a function.");
    
    @autoreleasepool {
        id <STFunction> function = [arguments objectAtIndex:1];
        return STFunctionApply(function, [STList new]);
    }
}

#pragma mark - • Core Lisp Functions

//-
//	function	parse
//	intention	To parse a string into an AST
//	forms {
//		(string) -> NSArray \
//			Parses string into an NSArray of STLists, STSymbols NSNumbers, and NSStrings.
//	}
//-
static id parse(STList *arguments, STScope *scope)
{
	if(arguments.count != 1)
		STRaiseIssue(arguments.creationLocation, @"parse takes exactly 1 parameter (string-to-parse), %ld given.", arguments.count);
	
	return STParseString([[arguments head] string], @"<<parse>>");
}

//-
//	function	eval
//	intention	To evaluate all expressions passed in
//	impure
//	forms {
//		(expression...) -> id \
//			Evaluates each expression and returns the result of evaluating the last expression.
//	}
//-
static id eval(STList *arguments, STScope *scope)
{
	id lastResult = nil;
	for (id expression in arguments)
		lastResult = STEvaluate(expression, scope);
	
	return lastResult;
}

//-
//	function	apply
//	intention	To apply a function.
//	impure
//	forms {
//		(function, parameters) -> id \
//			Apply the `function` with the `parameters` in the current scope, yielding the result.
//	}
//-
static id apply(STList *arguments, STScope *scope)
{
	if(arguments.count != 2)
		STRaiseIssue(arguments.creationLocation, @"apply requires 2 parameters (function, parameters), got %ld", arguments.count);
	
	id <STFunction> function = [arguments objectAtIndex:0];
	id parameters = [arguments objectAtIndex:1];
	if([parameters isKindOfClass:[NSArray class]])
		parameters = [[STList alloc] initWithArray:parameters];
	else if(![parameters isKindOfClass:[STList class]])
		STRaiseIssue(arguments.creationLocation, @"Wrong type given for apply's `parameters`, got %@, expected STList|NSArray.", [parameters className]);
	
	return [function applyWithArguments:parameters inScope:scope];
}

#pragma mark - • Control Flow

//-
//	function	break
//	intention	To raise a break exception.
//-
static id _break(STList *arguments, STScope *scope)
{
	@throw [STBreakException breakExceptionFrom:arguments.creationLocation];
	return nil;
}

//-
//	function	continue
//	intention	To raise a continue exception.
//-
static id _continue(STList *arguments, STScope *scope)
{
	@throw [STContinueException continueExceptionFrom:arguments.creationLocation];
	return nil;
}

#pragma mark -

//-
//	function	decide
//	intention	To provide basic control flow for Stein.
//	forms {
//		(condition, true-block) -> id \
//			Evaluates condition and calls true-block if condition is true. \
//			If the condition is true, the result of true-block is yielded, `false` otherwise.
//		(condition, true-block, false-block) -> id \
//			Evaluates the condition and calls true-block if the condition is true, or the \
//			false-block if the condition is false. The result of the called block is yielded.
// }
//-
static id decide(STList *arguments, STScope *scope)
{
	if(arguments.count != 2 && arguments.count != 3)
		STRaiseIssue(arguments.creationLocation, @"if given wrong number of parameters, expects 2 or 3, got %ld", arguments.count);
	
	if(STIsTrue(STEvaluate([arguments objectAtIndex:0], scope)))
	{
		id action = [arguments objectAtIndex:1];
		if([action respondsToSelector:@selector(flags)] && 
		   ST_FLAG_IS_SET([action flags], kSTListFlagIsDefinition))
		{
			return STEvaluate([[arguments objectAtIndex:1] allObjects], scope);
		}
		else
		{
			return STEvaluate([arguments objectAtIndex:1], scope);
		}
	}
	else if(arguments.count == 3)
	{
		id action = [arguments objectAtIndex:1];
		if([action respondsToSelector:@selector(flags)] && 
		   ST_FLAG_IS_SET([action flags], kSTListFlagIsDefinition))
		{
			return STEvaluate([[arguments objectAtIndex:2] allObjects], scope);
		}
		else
		{
			return STEvaluate([arguments objectAtIndex:2], scope);
		}
	}
	
	return STFalse;
}

//-
//	function	match
//	intention	To match a specified value against a list of values, \
//				evaluating a specified block based on the result.
//	forms {
//		(left-operand { right-operand	expression|{ expressions... }... } -> id
//	}
//-
static id match(STList *arguments, STScope *scope)
{
	if(arguments.count != 2)
		STRaiseIssue(arguments.creationLocation, @"match requires 2 parameters (left-operand, { right-operand\texpression|{ expressions... }... }, got %ld", arguments.count);
	
	id leftOperand = STEvaluate([arguments objectAtIndex:0], scope);
	for (STList *potentialMatch in [arguments objectAtIndex:1])
	{
		id rightOperand = STEvaluate([potentialMatch head], scope);
		if([leftOperand isEqual:rightOperand] || [rightOperand isEqualTo:ST_SYM(@"_")])
		{
			id action = [potentialMatch tail];
			if([action respondsToSelector:@selector(flags)] && 
			   ST_FLAG_IS_SET([action flags], kSTListFlagIsDefinition))
			{
				return STEvaluate([action allObjects], scope);
			}
			else
			{
				return STEvaluate(action, scope);
			}
		}
	}
	
	return STFalse;
}

#pragma mark - • Modules

//-
//	function	module
//	purpose		To create modules in the Stein programming language.
//	impure
//	forms {
//		(name definitions) -> STModule \
//			Creates a new module with `name` by evaluating the expressions in `definitions`.
//	}
//-
static id module(STList *arguments, STScope *scope)
{
	if(arguments.count != 2)
		STRaiseIssue(arguments.creationLocation, @"module requires exactly 2 parameters (name, definitions), got %ld.", arguments.count);
	
	NSString *name = [[arguments objectAtIndex:0] string];
	STModule *module = [scope valueForVariableNamed:name searchParentScopes:YES];
	if(module && ![module isKindOfClass:[STModule class]])
		STRaiseIssue(arguments.creationLocation, @"attempting to define a module with a name already dedicated to a binding of a different type.");
	
	if(!module)
	{
		module = [[STModule alloc] initWithName:name superscope:scope];
		[scope setValue:module forConstantNamed:name];
	}
	
	STEvaluate([[arguments objectAtIndex:1] allObjects], module);
	
	return module;
}

//-
//	function	include
//	purpose		To include all of the values of a scope/module into the current scope/module.
//	impure
//	forms {
//		(scope|module...) -> scope|module \
//			Includes all of the variables for the passed in scope/module objects into the current scope/module.
//	}
//-
static id include(STList *arguments, STScope *scope)
{
	for (STScope *module in arguments)
	{
		[scope setValuesForVariablesInScope:module];
	}
	
	return [arguments objectAtIndex:arguments.count - 1];
}

#pragma mark - • Dependencies

static NSString *const SearchDirectories[] = {
    @"./",
    @"~/Library/Frameworks",
    @"/Library/Frameworks",
    @"/System/Library/Frameworks",
    
    @"./SteinLibrary"
    @"~/Library/SteinLibrary",
    @"/Library/SteinLibrary",
};
static NSUInteger const SearchDirectoriesCount = (sizeof(SearchDirectories) / sizeof(SearchDirectories[0]));

//-
//  function    require
//  purpose     To evaluate a list of Stein files passed in.
//  impure
//  forms {
//      (require string...) -> nil
//  }
//-
static id _require(STList *arguments, STScope *scope)
{
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    for (__strong NSString *filename in arguments)
    {
        NSString *fullPath = nil;
        
        if([filename hasPrefix:@"/"] || [filename hasPrefix:@"."])
        {
            fullPath = filename;
        }
        else
        {
            if(![filename pathExtension])
            {
                filename = [filename stringByAppendingPathExtension:@"st"];
            }
            
            for (NSUInteger index = 0; index < SearchDirectoriesCount; index++)
            {
                NSString *searchDirectory = SearchDirectories[index];
                fullPath = [searchDirectory stringByAppendingPathComponent:filename];
                
                BOOL isDirectory = NO;
                if(([defaultManager fileExistsAtPath:fullPath isDirectory:&isDirectory]))
                {
                    if(isDirectory)
                    {
                        NSString *initPath = [fullPath stringByAppendingPathComponent:@"Prelude.st"];
                        if([defaultManager fileExistsAtPath:initPath])
                            fullPath = initPath;
                        else
                            STRaiseIssue(arguments.creationLocation, @"Library at path %@ is missing Prelude.st", fullPath);
                    }
                    
                    break;
                }
                else
                {
                    continue;
                }
                
                NSError *error = nil;
                NSString *fileContents = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
                if(!fileContents)
                    STRaiseIssue(arguments.creationLocation, @"Could not load file %@ for require", fullPath);
                
                STEvaluate(fileContents, scope);
            }
        }
    }
    
    return STNull;
}

//-
//  function    framework
//  purpose     To import a list of frameworks.
//  impure
//  forms {
//      (framework string...) -> nil
//  }
//-
static id framework(STList *arguments, STScope *scope)
{
    for (__strong NSString *filename in arguments)
    {
        NSString *fullPath = nil;
        
        if([filename hasPrefix:@"/"] || [filename hasPrefix:@"."])
        {
            fullPath = filename;
        }
        else
        {
            if(![filename pathExtension])
            {
                filename = [filename stringByAppendingPathExtension:@"framework"];
            }
            
            for (NSUInteger index = 0; index < SearchDirectoriesCount; index++)
            {
                NSString *searchDirectory = SearchDirectories[index];
                fullPath = [searchDirectory stringByAppendingPathComponent:filename];
                
                if([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
                {
                    break;
                }
                else
                {
                    continue;
                }
            }
            
            NSError *error = nil;
            if(![[NSBundle bundleWithPath:fullPath] loadAndReturnError:&error])
                STRaiseIssue(arguments.creationLocation, @"Could not load framework. Error %@", error);
        }
    }
    
    return STNull;
}

#pragma mark - • Mathematics

//-
//	function	+
//	intention	To add the objects given together.
//	forms {
//		(operand...) -> id \
//			Calls operatorAdd: on each operand passed in, collecting and yielding the result.
//	}
//-
static id plus(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand operatorAdd:rightOperand];
	}
	
	return leftOperand;
}

//-
//	function	-
//	intention	To subtract the objects given from each other.
//	forms {
//		(operand...) -> id \
//			Calls operatorSubtract: on each operand passed in, collecting and yielding the result.
//	}
//-
static id minus(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand operatorSubtract:rightOperand];
	}
	
	return leftOperand;
}

//-
//	function	*
//	intention	To multiply the objects given.
//	forms {
//		(operand...) -> id \
//			Calls operatorMultiply: on each operand passed in, collecting and yielding the result.
//	}
//-
static id multiply(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand operatorMultiply:rightOperand];
	}
	
	return leftOperand;
}

//-
//	function	/
//	intention	To divide the objects given into each other.
//	forms {
//		(operand...) -> id \
//			Calls operatorDivide: on each operand passed in, collecting and yielding the result.
//	}
//-
static id divide(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand operatorDivide:rightOperand];
	}
	
	return leftOperand;
}

//-
//	function	^
//	intention	To raise the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls operatorPower: on each operand passed in, collecting and yielding the result.
//	}
//-
static id power(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand operatorPower:rightOperand];
	}
	
	return leftOperand;
}

#pragma mark - Comparison

//-
//	function	=
//	intention	To compare the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls isEqual: on each operand passed in, collecting and yielding the result.
//	}
//-
static id equal(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		if(![leftOperand isEqual:rightOperand])
			return STFalse;
		
		leftOperand = rightOperand;
	}
	
	return STTrue;
}

//-
//	function	≠
//	intention	To compare the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls !isEqual: on each operand passed in, collecting and yielding the result.
//	}
//-
static id notEqual(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		if([leftOperand isEqual:rightOperand])
			return STFalse;
		
		leftOperand = rightOperand;
	}
	
	return STTrue;
}

//-
//	function	<
//	intention	To compare the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls compare: on each operand passed in, collecting and yielding the result.
//	}
//-
static id lessThan(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		NSComparisonResult result = [leftOperand compare:rightOperand];
		if(result != NSOrderedAscending)
			return STFalse;
		
		leftOperand = rightOperand;
	}
	
	return STTrue;
}

//-
//	function	≤
//	intention	To compare the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls compare: on each operand passed in, collecting and yielding the result.
//	}
//-
static id lessThanOrEqual(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		NSComparisonResult result = [leftOperand compare:rightOperand];
		if(result != NSOrderedAscending && result != NSOrderedSame)
			return STFalse;
		
		leftOperand = rightOperand;
	}
	
	return STTrue;
}

//-
//	function	>
//	intention	To compare the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls compare: on each operand passed in, collecting and yielding the result.
//	}
//-
static id greaterThan(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		NSComparisonResult result = [leftOperand compare:rightOperand];
		if(result != NSOrderedDescending)
			return STFalse;
		
		leftOperand = rightOperand;
	}
	
	return STTrue;
}

//-
//	function	≥
//	intention	To compare the objects given to each other.
//	forms {
//		(operand...) -> id \
//			Calls compare: on each operand passed in, collecting and yielding the result.
//	}
//-
static id greaterThanOrEqual(STList *arguments, STScope *scope)
{
	id leftOperand = [arguments head];
	for (id rightOperand in [arguments tail])
	{
		NSComparisonResult result = [leftOperand compare:rightOperand];
		if(result != NSOrderedDescending && result != NSOrderedSame)
			return STFalse;
		
		leftOperand = rightOperand;
	}
	
	return STTrue;
}

#pragma mark - • Logical

//-
//	function	or
//	intention	To check the objects given for truthiness.
//	forms {
//		(operand...) -> id \
//			Calls STIsTrue on each operand, returning the first operand that is true, or `false` if no operand is true.
//	}
//-
static id or(STList *arguments, STScope *scope)
{
	if(STIsTrue([arguments head]))
		return [arguments head];
	
	for (id object in [arguments tail])
	{
		if(STIsTrue(object))
			return object;
	}
	
	return STFalse;
}

//-
//	function	and
//	intention	To check the objects given for truthiness.
//	forms {
//		(operand...) -> id \
//			Calls STIsTrue on each operand, returning false for the first operand that is `false`, or `true` if all of the operands are true.
//	}
//-
static id and(STList *arguments, STScope *scope)
{
	BOOL isTrue = STIsTrue([arguments head]);
	if(isTrue)
	{
		for (id object in [arguments tail])
		{
			isTrue = isTrue && STIsTrue(object);
			if(!isTrue)
				break;
		}
	}
	
	return [NSNumber numberWithBool:isTrue];
}

//-
//	function	not
//	intention	To invert the truthiness of a given value.
//-
static id not(STList *arguments, STScope *scope)
{
	if(arguments.count != 1)
		STRaiseIssue(arguments.creationLocation, @"not requires exactly one parameter (operand).");
	
	return [NSNumber numberWithBool:!STIsTrue([arguments head])];
}

#pragma mark - • Bridging

//-
//	function	extern
//	intention	To bring native constants and functions into a Stein execution context.
//	impure
//	forms {
//		(type symbol-name) -> id \
//			Looks up the native constant specified by `symbol-name`, and if found, its value will be treated as `type`.
//		(type symbol-name(parameter-type...)) -> STBridgedFunction \
//			Looks up the native function specified by `symbol-name`, and if found, it will be wrapped into an STBridgedFunction instance whose return type is `type` and whose parameter types are `parameter-type...`.
//	}
//-
static id _extern(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"extern requires at least 2 parameters (type symbol) or (type symbol(type...)).");
	
	NSString *symbolType = STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string]);
	NSString *symbolName = [[arguments objectAtIndex:1] string];
	
	id result = STNull;
	if(arguments.count == 2)
	{
		void *value = dlsym(RTLD_DEFAULT, [symbolName UTF8String]);
		NSCAssert((value != NULL), @"Could not find constant named %@.", symbolName);
		
		result = STTypeBridgeConvertValueOfTypeIntoObject(value, [symbolType UTF8String]);
	}
	else if(arguments.count == 3)
	{
		NSMutableString *signature = [NSMutableString stringWithString:symbolType];
		for (STSymbol *type in [arguments objectAtIndex:2])
			[signature appendString:STTypeBridgeGetObjCTypeForHumanReadableType([type string])];
		
		result = [[STBridgedFunction alloc] initWithSymbolNamed:symbolName 
													  signature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]];
	}
	
	[scope setValue:result forConstantNamed:symbolName];
	
	return result;
}

#pragma mark -

//-
//	function	ref
//	intention	To return a pointer of a specified type for a specified value.
//	forms {
//		(type, value) -> STPointer \
//			Creates an STPointer whose `value` is of `type`.
//	}
//-
static id ref(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"ref requires 2 parameters (type, initialValue).");
	
	NSString *type = STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string]);
	
	STPointer *pointer = [STPointer pointerWithType:[type UTF8String]];
	pointer.value = STEvaluate([arguments objectAtIndex:1], scope);
	
	return pointer;
}

//-
//	function	ref-array
//	intention	To create a pointer array of a specified type and length.
//	forms {
//		(type length) -> STPointer \
//			Creates an STArrayPointer of `type` and of `length`.
//	}
//-
static id ref_array(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"ref-array requires 2 parameters (type, length).");
	
	NSString *type = STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string]);
	NSUInteger length = [STEvaluate([arguments objectAtIndex:1], scope) unsignedIntegerValue];
	
	return [STPointer arrayPointerOfLength:length type:[type UTF8String]];
}

#pragma mark -

//-
//	function	to-native-function
//	intention	To wrap Stein function's into native function wrappers that can be used as C function-pointers.
//-
static id to_native_function(STList *arguments, STScope *scope)
{
	if([arguments count] < 3)
		STRaiseIssue(arguments.creationLocation, @"to-native-function requires 3 parameters (return-type (param-type...) stein-function).");
	
	NSMutableString *typeString = [NSMutableString stringWithString:STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string])];
	for (STSymbol *type in [arguments objectAtIndex:1])
		[typeString appendString:STTypeBridgeGetObjCTypeForHumanReadableType(type.string)];
	
	NSObject < STFunction > *function = STEvaluate([arguments objectAtIndex:2], scope);
	
	return [[STNativeFunctionWrapper alloc] initWithFunction:function 
												   signature:[NSMethodSignature signatureWithObjCTypes:[typeString UTF8String]]];
}

#pragma mark - • Collection Creation

//-
//	function	array
//	intention	To create instances of NSArray
//	forms {
//		(null) -> NSArray \
//			Creates an empty array
//		(value...) -> NSArray \
//			Creates an array with the specified `value[s]...`
//	}
//-
static id array(STList *arguments, STScope *scope)
{
	//Special case for `array ()`
	if(arguments.count == 1 && [arguments head] == STNull)
		return [NSArray array];
	
	return [arguments.allObjects copy];
}

//-
//	function	list
//	intention	To create instances of STList
//	forms {
//		(null) -> STList \
//			Creates an empty list
//		(value...) -> STList \
//			Creates a list with the specified `value[s]...`
//	}
//-
static id list(STList *arguments, STScope *scope)
{
	//Special case for `list ()`
	if(arguments.count == 1 && [arguments head] == STNull)
		return [STList new];
	
	return [arguments copy];
}

//-
//	function	dictionary
//	intention	To create instances of NSDictionary
//	forms {
//		(null) -> NSDictionary \
//			Creates an empty dictionary
//		(key value...) -> NSDictionary \
//			Creates a dictionary with the specified `key value[s]...`
//	}
//-
static id dictionary(STList *arguments, STScope *scope)
{
	//Special case for `dictionary ()`
	if(arguments.count == 1 && [arguments head] == STNull)
		return [NSDictionary dictionary];
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	id key = nil;
	for (id argument in arguments)
	{
		if(!key)
		{
			key = argument;
		}
		else
		{
			if(argument != STNull)
				[dictionary setObject:argument forKey:key];
			
			key = nil;
		}
	}
	
	return [dictionary copy];
}

//-
//	function	set
//	intention	To create instances of NSMutableSet
//	forms {
//		(null) -> NSSet \
//			Creates an empty set
//		(value...) -> NSSet \
//			Creates a set with the specified `value[s]...`
//	}
//-
static id set(STList *arguments, STScope *scope)
{
	//Special case for `set ()`
	if(arguments.count == 1 && [arguments head] == STNull)
		return [NSSet set];
	
	return [NSSet setWithArray:arguments.allObjects];
}

//-
//	function	index-set
//	intention	To create instances of NSIndexSet
//	forms {
//		(null) -> NSIndexSet \
//			Creates an empty index set
//		(value...) -> NSIndexSet \
//			Creates an index set with the specified `value[s]...`
//	}
//-
static id index_set(STList *arguments, STScope *scope)
{
	//Special case for `index-set ()`
	if(arguments.count == 1 && [arguments head] == STNull)
		return [NSMutableDictionary dictionary];
	
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	for (id argument in arguments)
	{
		[indexSet addIndex:[argument unsignedIntegerValue]];
	}
	
	return [indexSet copy];
}

//-
//	function	range
//	intention	To create instances of STRange
//	forms {
//		(location length) -> STRange \
//			Creates a range with a specified `location` and `length`.
//	}
//-
static id range(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"range requires 2 parameters (location, length).");
	
	return [[STRange alloc] initWithRange:NSMakeRange([[arguments objectAtIndex:0] unsignedIntegerValue], 
													  [[arguments objectAtIndex:1] unsignedIntegerValue])];
}

#pragma mark - Public Interface

STScope *STBuiltInFunctionScope()
{
	STScope *functionScope = [STScope new];
	functionScope.name = @"Global Scope";
	
	//Core
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&let
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"let"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&setBang
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"set!"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&unsetBang
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"unset!"];
	
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&load
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"load"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&_super
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"super"];
    
    [functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&autoreleasepool
                                                        evaluatesOwnArguments:YES]
           forConstantNamed:@"autoreleasepool"];
	
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&parse
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"parse"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&eval
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"eval"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&apply
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"apply"];
	
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&_break
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"break"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&_continue
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"continue"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&decide
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"decide"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&match
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"match"];
	
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&module
                                                        evaluatesOwnArguments:YES]
		   forConstantNamed:@"module"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&include
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"include"];
	
    //Dependencies
    [functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&_require
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"require"];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&framework
                                                        evaluatesOwnArguments:NO]
		   forConstantNamed:@"framework"];
    
	//Mathematics
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&plus
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"+" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&minus
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"-" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&multiply
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"*" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&divide
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"/" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&power
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"^"
		 searchParentScopes:NO];
	
	//Comparison
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&equal
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"=" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&notEqual
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"≠" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&lessThan
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"<" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&lessThanOrEqual
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"≤" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&greaterThan
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@">" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&greaterThanOrEqual
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"≥" 
		 searchParentScopes:NO];
	
	//Logical
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&or
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"or" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&and
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"and" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&not
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"not" 
		 searchParentScopes:NO];
	
	//Bridging
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&_extern
                                                        evaluatesOwnArguments:YES]
		   forVariableNamed:@"extern" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&ref
                                                        evaluatesOwnArguments:YES]
		   forVariableNamed:@"ref" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&ref_array
                                                        evaluatesOwnArguments:YES]
		   forVariableNamed:@"ref-array" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&to_native_function
                                                        evaluatesOwnArguments:YES]
		   forVariableNamed:@"to-native-function" 
		 searchParentScopes:NO];
	
	//Collection Creation
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&array
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"array" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&list
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"list" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&dictionary
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"dictionary" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&set
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"set" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&index_set
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"index-set" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&range
                                                        evaluatesOwnArguments:NO]
		   forVariableNamed:@"range" 
		 searchParentScopes:NO];
	
	
	//Constants
	[functionScope setValue:[NSDecimalNumber minimumDecimalNumber] forConstantNamed:@"$min-number"];
	[functionScope setValue:[NSDecimalNumber maximumDecimalNumber] forConstantNamed:@"$max-number"];
	
	[functionScope setValue:[[NSProcessInfo processInfo] arguments] forConstantNamed:@"$args"];
	[functionScope setValue:[[NSProcessInfo processInfo] environment] forConstantNamed:@"$env"];
	
	[functionScope setValue:STTrue forConstantNamed:@"true"];
	[functionScope setValue:STFalse forConstantNamed:@"false"];
	[functionScope setValue:ST_SYM(@"_") forConstantNamed:@"_"];
	
	[functionScope setValue:@"" forVariableNamed:@"$file" searchParentScopes:NO];
	
	return functionScope;
}
