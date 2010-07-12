//
//  STNativeBlock.m
//  stein
//
//  Created by Peter MacWhinnie on 10/1/18.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STNativeBlock.h"
#import "STFunctionInvocation.h"
#import "STTypeBridge.h"
#import "Block_private.h" //Taken from LLVM compiler-rt.

@implementation STNativeBlock

#pragma mark Creation

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithBlock:(id)block signature:(NSMethodSignature *)signature
{
	if((self = [super init]))
	{
		mBlock = block;
		
		struct Block_layout *blockLayout = (struct Block_layout *)(mBlock);
		mInvocation = [[STFunctionInvocation alloc] initWithFunction:blockLayout->invoke signature:signature];
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark STFunction

- (BOOL)evaluatesOwnArguments
{
	return NO;
}

- (STScope *)superscope
{
	return nil;
}

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)scope
{
	NSMethodSignature *functionSignature = mInvocation.functionSignature;
	NSAssert(([arguments count] == [functionSignature numberOfArguments] - 1), 
			 @"Wrong number of arguments given to %@. Expected %ld, got %ld", self, [functionSignature numberOfArguments] - 1, [arguments count]);
	
	[mInvocation setArgument:mBlock atIndex:0];
	
	NSUInteger numberOfArguments = [functionSignature numberOfArguments] - 1;
	for (NSUInteger index = 0; index < numberOfArguments; index++)
	{
		const char *argumentSignature = [functionSignature getArgumentTypeAtIndex:index + 1];
		
		//We use alloca so that the buffer is automatically freed when this function returns.
		void *buffer = alloca(STTypeBridgeGetSizeOfObjCType(argumentSignature));
		
		STTypeBridgeConvertObjectIntoType([arguments objectAtIndex:index], argumentSignature, buffer);
		
		[mInvocation setArgument:buffer atIndex:index + 1];
	}
	
	
	[mInvocation apply];
	
	//If it returns void, it should be nil
	if([functionSignature methodReturnType][0] == 'v')
		return STNull;
	
	void *returnValue = NULL;
	[mInvocation getReturnValue:&returnValue];
	
	return STTypeBridgeConvertValueOfTypeIntoObject(returnValue, [functionSignature methodReturnType]);
}

@end
