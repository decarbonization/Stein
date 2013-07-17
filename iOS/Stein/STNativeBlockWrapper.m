//
//  STNativeBlockWrapper.m
//  stein
//
//  Created by Kevin MacWhinnie on 12/15/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "STNativeBlockWrapper.h"
#import "STList.h"
#import "STNativeFunctionWrapper.h"
#import <objc/runtime.h>
#import <objc/message.h>

static void STNativeBlockWrapperCopyHelper(void *dst, STNativeBlockWrapper *src)
{
}

static void STNativeBlockWrapperDisposeHelper(STNativeBlockWrapper *src)
{
    objc_msgSend(src, NSSelectorFromString(@"release"));
}

@implementation STNativeBlockWrapper

- (void)dealloc
{
    free(descriptor);
    descriptor = NULL;
}

- (id)initWithFunction:(NSObject <STFunction> *)function signature:(NSMethodSignature *)signature
{
    if((self = [super init]))
    {
        flags = BLOCK_HAS_COPY_DISPOSE;
        
        mNativeFunctionWrapper = [[STNativeFunctionWrapper alloc] initWithFunction:function
                                                                         signature:signature];
        
        descriptor = malloc(sizeof(struct Block_descriptor_1));
        memset(descriptor, 0, sizeof(struct Block_descriptor_1));
        descriptor->size = class_getInstanceSize([self class]);
        descriptor->copy_helper = (void *)&STNativeBlockWrapperCopyHelper;
        descriptor->dispose_helper = (void *)&STNativeBlockWrapperDisposeHelper;
    }
    
    return self;
}

#pragma mark - Properties

- (NSObject <STFunction> *)function
{
    return mNativeFunctionWrapper.function;
}

- (NSMethodSignature *)signature
{
    return mNativeFunctionWrapper.signature;
}

#pragma mark - Implementing STFunction

- (STScope *)superscope
{
	return [mNativeFunctionWrapper.function superscope];
}

- (BOOL)evaluatesOwnArguments
{
	return [mNativeFunctionWrapper.function evaluatesOwnArguments];
}

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)scope
{
	return [mNativeFunctionWrapper.function applyWithArguments:[arguments tail] inScope:scope];
}

@end
