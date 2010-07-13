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

#import "STNativeFunctionWrapper.h"
#import "STNativeBlock.h"
#import "STTypeBridge.h"
#import "STStructClasses.h"
#import "STPointer.h"
#import <dlfcn.h>

#import "STList.h"
#import "STSymbol.h"

#import "STInterpreter.h"
#import "STScope.h"

typedef id(*STBuiltInFunctionImplementation)(STList *arguments, STScope *scope);

@interface STBuiltInFunction : NSObject <STFunction>
{
	STBuiltInFunctionImplementation mImplementation;
	BOOL mEvaluatesOwnArguments;
}

#pragma mark Initialization

/*!
 @abstract	Initialize the receiver with a specified implementation and whether or not it evaluates its own arguments.
 */
- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments;

#pragma mark -
#pragma mark Properties

/*!
 @abstract	The implementation of the built in function object.
 */
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

#pragma mark -
#pragma mark Properties

@synthesize evaluatesOwnArguments = mEvaluatesOwnArguments;
@synthesize implementation = mImplementation;

- (STScope *)superscope
{
	return nil;
}

#pragma mark -
#pragma mark Application

- (id)applyWithArguments:(STList *)message inScope:(STScope *)scope
{
	return (*mImplementation)(message, scope);
}

@end

#pragma mark -
#pragma mark Function Implementations

#pragma mark • Core

static id let(STList *arguments, STScope *scope)
{
	NSUInteger numberOfArguments = arguments.count;
	if(numberOfArguments == 1)
	{
		NSString *name = [[arguments objectAtIndex:0] string];
		[scope removeValueForVariableNamed:name searchParentScopes:YES];
	}
	else if(numberOfArguments >= 3)
	{
		NSString *name = [[arguments objectAtIndex:0] string];
		
		STSymbol *directive = [arguments objectAtIndex:1];
		if([directive isEqualTo:@"="])
		{
			id expression = [arguments sublistFromIndex:2];
			if([expression count] == 1 && 
			   [[expression head] isKindOfClass:[STList class]] && 
			   ST_FLAG_IS_SET([[expression head] flags], kSTListFlagIsDefinition))
			{
				expression = [expression head];
			}
			
			id value = STEvaluate(expression, scope);
			[scope setValue:value forVariableNamed:name searchParentScopes:YES];
			return value;
		}
		else if([directive isEqualTo:@"extend"])
		{
			NSCAssert((numberOfArguments == 4), 
					  @"Expected exactly 4 arguments for class declaration, got %ld.", numberOfArguments);
			
			Class superclass = STEvaluate([arguments objectAtIndex:2], scope);
			STList *declarations = [arguments objectAtIndex:3];
			
			return STDefineClass(name, superclass, declarations);
		}
		else
		{
			STRaiseIssue(arguments.creationLocation, @"Malformed let statement, directive {%@} is undefined.", [directive string]);
		}
	}
	else
	{
		STRaiseIssue(arguments.creationLocation, @"malformed let statement");
	}
}

#pragma mark -
#pragma mark • Mathematics

static id plus(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByAdding:rightOperand];
	}
	
	return leftOperand ?: STNull;
}

static id minus(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberBySubtracting:rightOperand];
	}
	
	return leftOperand ?: STNull;
}

static id multiply(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByMultiplyingBy:rightOperand];
	}
	
	return leftOperand ?: STNull;
}

static id divide(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByDividingBy:rightOperand];
	}
	
	return leftOperand ?: STNull;
}

static id power(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByRaisingToPower:[rightOperand unsignedIntegerValue]];
	}
	
	return leftOperand ?: STNull;
}

#pragma mark -
#pragma mark Comparison

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

#pragma mark -
#pragma mark • Logical

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

static id not(STList *arguments, STScope *scope)
{
	if(arguments.count != 1)
		STRaiseIssue(arguments.creationLocation, @"not requires exactly one parameter (operand).");
	
	return [NSNumber numberWithBool:!STIsTrue([arguments head])];
}

#pragma mark -
#pragma mark • Bridging

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
	
	[scope setValue:result forVariableNamed:symbolName searchParentScopes:NO];
	
	return result;
}

#pragma mark -

static id ref(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"ref requires 2 parameters (type, initialValue).");
	
	NSString *type = STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string]);
	
	STPointer *pointer = [STPointer pointerWithType:[type UTF8String]];
	pointer.value = STEvaluate([arguments objectAtIndex:1], scope);
	
	return pointer;
}

static id ref_array(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"ref-array requires 2 parameters (type, length).");
	
	NSString *type = STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string]);
	NSUInteger length = [STEvaluate([arguments objectAtIndex:1], scope) unsignedIntegerValue];
	
	return [STPointer arrayPointerOfLength:length type:[type UTF8String]];
}

#pragma mark -

static id to_native_function(STList *arguments, STScope *scope)
{
	if([arguments count] < 3)
		STRaiseIssue(arguments.creationLocation, @"to-native-function requires 3 parameters.");
	
	NSMutableString *typeString = [NSMutableString stringWithString:STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string])];
	for (STSymbol *type in [arguments objectAtIndex:1])
		[typeString appendString:STTypeBridgeGetObjCTypeForHumanReadableType(type.string)];
	
	NSObject < STFunction > *function = STEvaluate([arguments objectAtIndex:2], scope);
	
	return [[STNativeFunctionWrapper alloc] initWithFunction:function 
												   signature:[NSMethodSignature signatureWithObjCTypes:[typeString UTF8String]]];
}

static id to_native_block(STList *arguments, STScope *scope)
{
	if([arguments count] < 3)
		STRaiseIssue(arguments.creationLocation, @"to-native-block requires 3 parameters.");
	
	NSMutableString *typeString = [NSMutableString stringWithString:STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string])];
	
	//The 'block' parameter.
	[typeString appendString:@"@"];
	
	for (STSymbol *type in [arguments objectAtIndex:1])
		[typeString appendString:STTypeBridgeGetObjCTypeForHumanReadableType(type.string)];
	
	id block = STEvaluate([arguments objectAtIndex:2], scope);
	
	return [[STNativeBlock alloc] initWithBlock:block 
									  signature:[NSMethodSignature signatureWithObjCTypes:[typeString UTF8String]]];
}

#pragma mark -
#pragma mark • Collection Creation

static id array(STList *arguments, STScope *scope)
{
	return [arguments.allObjects mutableCopy];
}

static id list(STList *arguments, STScope *scope)
{
	return [arguments copy];
}

static id dictionary(STList *arguments, STScope *scope)
{
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
	
	return dictionary;
}

static id set(STList *arguments, STScope *scope)
{
	return [NSMutableSet setWithArray:arguments.allObjects];
}

static id index_set(STList *arguments, STScope *scope)
{
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	for (id argument in arguments)
	{
		[indexSet addIndex:[argument unsignedIntegerValue]];
	}
	
	return indexSet;
}

static id range(STList *arguments, STScope *scope)
{
	if(arguments.count < 2)
		STRaiseIssue(arguments.creationLocation, @"range requires 2 parameters (location, length).");
	
	return [[STRange alloc] initWithRange:NSMakeRange([[arguments objectAtIndex:0] unsignedIntegerValue], 
													  [[arguments objectAtIndex:1] unsignedIntegerValue])];
}

#pragma mark -
#pragma mark Public Interface

STScope *STBuiltInFunctionScope()
{
	STScope *functionScope = [STScope new];
	
	//Core
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&let evaluatesOwnArguments:YES] 
		   forVariableNamed:@"let" 
		 searchParentScopes:NO];
	
	//Mathematics
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&plus evaluatesOwnArguments:NO] 
		   forVariableNamed:@"+" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&minus evaluatesOwnArguments:NO] 
		   forVariableNamed:@"-" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&multiply evaluatesOwnArguments:NO] 
		   forVariableNamed:@"*" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&divide evaluatesOwnArguments:NO] 
		   forVariableNamed:@"/" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&power evaluatesOwnArguments:NO] 
		   forVariableNamed:@"**" 
		 searchParentScopes:NO];
	
	//Comparison
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&equal evaluatesOwnArguments:NO] 
		   forVariableNamed:@"=" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&notEqual evaluatesOwnArguments:NO] 
		   forVariableNamed:@"≠" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&lessThan evaluatesOwnArguments:NO] 
		   forVariableNamed:@"<" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&lessThanOrEqual evaluatesOwnArguments:NO] 
		   forVariableNamed:@"≤" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&greaterThan evaluatesOwnArguments:NO] 
		   forVariableNamed:@">" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&greaterThanOrEqual evaluatesOwnArguments:NO] 
		   forVariableNamed:@"≥" 
		 searchParentScopes:NO];
	
	//Logical
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&or evaluatesOwnArguments:NO] 
		   forVariableNamed:@"or" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&and evaluatesOwnArguments:NO] 
		   forVariableNamed:@"and" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&not evaluatesOwnArguments:NO] 
		   forVariableNamed:@"not" 
		 searchParentScopes:NO];
	
	//Bridging
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&_extern evaluatesOwnArguments:YES] 
		   forVariableNamed:@"extern" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&ref evaluatesOwnArguments:YES] 
		   forVariableNamed:@"ref" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&ref_array evaluatesOwnArguments:YES] 
		   forVariableNamed:@"ref-array" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&to_native_function evaluatesOwnArguments:YES] 
		   forVariableNamed:@"to-native-function" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&to_native_block evaluatesOwnArguments:YES] 
		   forVariableNamed:@"to-native-block" 
		 searchParentScopes:NO];
	
	//Collection Creation
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&array evaluatesOwnArguments:NO] 
		   forVariableNamed:@"array" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&list evaluatesOwnArguments:NO] 
		   forVariableNamed:@"list" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&dictionary evaluatesOwnArguments:NO] 
		   forVariableNamed:@"dictionary" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&set evaluatesOwnArguments:NO] 
		   forVariableNamed:@"set" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&index_set evaluatesOwnArguments:NO] 
		   forVariableNamed:@"index-set" 
		 searchParentScopes:NO];
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&range evaluatesOwnArguments:NO] 
		   forVariableNamed:@"range" 
		 searchParentScopes:NO];
	
	
	//Constants
	[functionScope setValue:[NSDecimalNumber maximumDecimalNumber] 
		   forVariableNamed:@"$MaxNumber" 
		 searchParentScopes:NO];
	[functionScope setValue:[NSDecimalNumber minimumDecimalNumber] 
		   forVariableNamed:@"$MinNumber" 
		 searchParentScopes:NO];
	[functionScope setValue:[[NSProcessInfo processInfo] arguments] 
		   forVariableNamed:@"$Args" 
		 searchParentScopes:NO];
	[functionScope setValue:[[NSProcessInfo processInfo] environment] 
		   forVariableNamed:@"$Env" 
		 searchParentScopes:NO];
	
	[functionScope setValue:STTrue 
		   forVariableNamed:@"true" 
		 searchParentScopes:NO];
	[functionScope setValue:STFalse 
		   forVariableNamed:@"false" 
		 searchParentScopes:NO];
	
	return functionScope;
}
