//
//  STBuiltInFunctions.m
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STBuiltInFunctions.h"
#import "STInterpreter.h"
#import "STObjectBridge.h"
#import "STList.h"
#import "STScope.h"
#import "STSymbol.h"

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
	
	return leftOperand;
}

static id minus(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberBySubtracting:rightOperand];
	}
	
	return leftOperand;
}

static id multiply(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByMultiplyingBy:rightOperand];
	}
	
	return leftOperand;
}

static id divide(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByDividingBy:rightOperand];
	}
	
	return leftOperand;
}

static id power(STList *arguments, STScope *scope)
{
	NSDecimalNumber *leftOperand = [arguments head];
	for (NSDecimalNumber *rightOperand in [arguments tail])
	{
		leftOperand = [leftOperand decimalNumberByRaisingToPower:[rightOperand unsignedIntegerValue]];
	}
	
	return leftOperand;
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
		STRaiseIssue(arguments.creationLocation, @"not requires exactly one parameter.");
	
	return [NSNumber numberWithBool:!STIsTrue([arguments head])];
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
