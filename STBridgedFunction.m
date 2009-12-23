//
//  STBridgedFunction.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STBridgedFunction.h"
#import "STFunctionInvocation.h"
#import "STTypeBridge.h"
#import <dlfcn.h>

@implementation STBridgedFunction

#pragma mark Destruction

- (void)dealloc
{
	[mInvocation release];
	mInvocation = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithSymbol:(void *)symbol signature:(NSMethodSignature *)signature
{
	NSParameterAssert(symbol);
	NSParameterAssert(signature);
	
	if((self = [super init]))
	{
		mInvocation = [[STFunctionInvocation alloc] initWithFunction:symbol signature:signature];
		
		return self;
	}
	return nil;
}

- (id)initWithSymbolNamed:(NSString *)symbolName signature:(NSMethodSignature *)signature
{
	NSParameterAssert(symbolName);
	NSParameterAssert(signature);
	
	void *function = dlsym(RTLD_DEFAULT, [symbolName UTF8String]);
	NSAssert((function != NULL), @"Could not resolve function for %@.", symbolName);
	
	return [self initWithSymbol:function signature:signature];
}

#pragma mark -
#pragma mark STFunction

- (BOOL)evaluatesOwnArguments
{
	return NO;
}

- (STEvaluator *)evaluator
{
	return nil;
}

- (id)applyWithArguments:(STList *)arguments inScope:(NSMutableDictionary *)scope
{
	NSMethodSignature *functionSignature = mInvocation.functionSignature;
	for (NSUInteger index = 0; index < [functionSignature numberOfArguments]; index++)
	{
		const char *argumentSignature = [functionSignature getArgumentTypeAtIndex:index];
		
		//We use alloca so that the buffer is automatically freed when this function returns.
		void *buffer = alloca(STTypeBridgeSizeofObjCType(argumentSignature));
		
		STTypeBridgeConvertObjectIntoType([arguments objectAtIndex:index], argumentSignature, buffer);
		
		[mInvocation setArgument:buffer atIndex:index];
	}
	
	[mInvocation invoke];
	
	//If it returns void, it should be nil
	if([functionSignature methodReturnType][0] == 'v')
		return STNull;
	
	void *returnValue = NULL;
	[mInvocation getReturnValue:&returnValue];
	
	return STTypeBridgeConvertValueOfTypeIntoObject(returnValue, [functionSignature methodReturnType]);
}

@end
