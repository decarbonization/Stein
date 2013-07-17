//
//  STNativeBlockWrapper.h
//  stein
//
//  Created by Kevin MacWhinnie on 12/15/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STFunction.h"

@class STNativeFunctionWrapper;

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26),
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29),
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};

@interface STNativeBlockWrapper : NSObject <STFunction>
{
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1 {
        unsigned long int reserved;
    	unsigned long int size;
    	void (*copy_helper)(void *dst, void *src);
    	void (*dispose_helper)(void *src);
        const char *signature;
    } *descriptor;
    
    STNativeFunctionWrapper *mNativeFunctionWrapper;
}

///Initialize the receiver with a specified function object, and a specified type signature.
///
/// \param		function	The function object to create a native wrapper for. May not be nil. May not be a STNativeFunctionWrapper.
/// \param		signature	The signature that describes the function object's return type and parameters. May not be nil.
/// \result		A fully initialized function wrapper.
///
///This method raises an exception if any issues arise while creating the function wrapper
///
///This is the designated initializer of STNativeFunctionWrapper.
- (id)initWithFunction:(NSObject <STFunction> *)function signature:(NSMethodSignature *)signature;

#pragma mark - Properties

///The function that the native function wrapper is wrapping.
@property (readonly) NSObject <STFunction> *function;

///The signature of the function that the native function wrapper is wrapping.
@property (readonly) NSMethodSignature *signature;

@end
