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

id STBuiltInFunction_let(STList *arguments, STScope *scope)
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
#pragma mark • Public Interface

STScope *STBuiltInFunctionScope()
{
	STScope *functionScope = [STScope new];
	
	//Core Functions
	[functionScope setValue:[[STBuiltInFunction alloc] initWithImplementation:&STBuiltInFunction_let 
														evaluatesOwnArguments:YES] 
		   forVariableNamed:@"let" 
		 searchParentScopes:NO];
	
	return functionScope;
}
