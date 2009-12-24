//
//  STFunctionInvocation.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ffi/ffi.h>

/*!
 @class
 @abstract	The STFunctionInvocation class is an analogue to NSInvocation intended for application of arbitrary functions.
 */
@interface STFunctionInvocation : NSObject
{
	/* owner */	NSMethodSignature *mFunctionSignature;
	
	/* owner */	ffi_cif *mClosureInformation;
	/* weak */	void *mFunctionPointer;
	
	/* owner */	ffi_type *mResultType;
	/* owner */	void *mResultBuffer;
	
	/* owner */	ffi_type **mArgumentTypes;
	/* owner */	void **mArgumentValues;
}

#pragma mark Initialization

/*!
 @method
 @abstract	Initialize the receiver with a specified function pointer, and a specified signature describing said function pointer.
 @param		function	The function pointer the receiver will be invoking. May not be nil.
 @param		signature	A method signature object that describes the parameters and return value of the function pointer. May not be nil.
 @result	A fully initialized function invocation object.
 */
- (id)initWithFunction:(void *)function signature:(NSMethodSignature *)signature;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The signature of the function the invocation is to apply.
 */
@property (readonly) NSMethodSignature *functionSignature;

#pragma mark -
#pragma mark Arguments

/*!
 @method
 @abstract	Set a specified value for an argument at a specified offset.
 @param		argumnet	The value of the argument. May be NULL.
 @param		index		The offset of the argument whose value is to be set.
 */
- (void)setArgument:(void *)argument atIndex:(NSUInteger)index;

/*!
 @method
 @abstract	Get the value for an argument at a specified offset.
 @param		argument	A pointer to write the argument's value into. May not be NULL.
 @param		index		The offset of the argument whose value should be fetched.
 */
- (void)getArgument:(void **)argument atIndex:(NSUInteger)index;

#pragma mark -
#pragma mark Return Value

/*!
 @method
 @abstract	Get the return value of the invocation. Only valid after calling -[STFunctionInvocation invoke].
 */
- (void)getReturnValue:(void **)returnValue;

#pragma mark -
#pragma mark Invocation

/*!
 @method
 @abstract	Apply the function the invocation has been setup to invoke.
 */
- (void)apply;
@end
