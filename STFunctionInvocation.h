//
//  STFunctionInvocation.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/15.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ffi/ffi.h>

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

- (id)initWithFunction:(void *)function signature:(NSMethodSignature *)signature;

#pragma mark -
#pragma mark Properties

@property (readonly) NSMethodSignature *functionSignature;

#pragma mark -
#pragma mark Arguments

- (void)setArgument:(void *)argument atIndex:(NSUInteger)index;
- (void)getArgument:(void **)argument atIndex:(NSUInteger)index;

#pragma mark -
#pragma mark Return Value

- (void)getReturnValue:(void **)returnValue;

#pragma mark -
#pragma mark Invocation

- (void)invoke;
@end
