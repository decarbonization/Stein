//
//  STFunctionInvocation.h
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ffi.h"

///The STFunctionInvocation class is an analogue to NSInvocation intended for application of arbitrary functions.
@interface STFunctionInvocation : NSObject
{
	NSMethodSignature *mFunctionSignature;
	
	ffi_cif *mClosureInformation;
	void *mFunctionPointer;
	
	ffi_type *mResultType;
	void *mResultBuffer;
	
	ffi_type **mArgumentTypes;
	void **mArgumentValues;
}

#pragma mark Initialization

///Initialize the receiver with a specified function pointer, and a specified signature describing said function pointer.
///
/// \param	function	The function pointer the receiver will be invoking. May not be nil.
/// \param	signature	A method signature object that describes the parameters and return value of the function pointer. May not be nil.
///
/// \result	A fully initialized function invocation object.
- (id)initWithFunction:(void *)function signature:(NSMethodSignature *)signature;

#pragma mark - Properties

///The signature of the function the invocation is to apply.
@property (readonly) NSMethodSignature *functionSignature;

#pragma mark - Arguments

///Set a specified value for an argument at a specified offset.
///
/// \param	argumnet	The value of the argument. May be NULL.
/// \param	index		The offset of the argument whose value is to be set.
- (void)setArgument:(void *)argument atIndex:(NSUInteger)index;

///Get the value for an argument at a specified offset.
///
/// \param	argument	A pointer to write the argument's value into. May not be NULL.
/// \param	index		The offset of the argument whose value should be fetched.
- (void)getArgument:(void **)argument atIndex:(NSUInteger)index;

#pragma mark - Return Value

///Get the return value of the invocation. Only valid after calling -[STFunctionInvocation invoke].
- (void)getReturnValue:(void **)returnValue;

#pragma mark - Invocation

///Apply the function the invocation has been setup to invoke.
- (void)apply;
@end
