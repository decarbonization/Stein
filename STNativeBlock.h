//
//  STNativeBlock.h
//  stein
//
//  Created by Peter MacWhinnie on 10/1/18.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

@class STFunctionInvocation;

/*!
 @class
 @abstract	The STNativeBlock class is responsible for wrapping Objective-C block objects for use with Stein.
 */
@interface STNativeBlock : NSObject < STFunction >
{
	id mBlock;
	STFunctionInvocation *mInvocation;
}
/*!
 @method
 @abstract	Initialize the receiver with a specified block object, and a specified signature.
 @param		block		A block object to wrap. May not be nil.
 @param		signature	The type signature of the block object. The first parameter of this signature should be an object, this is the invisible parameter that 'block' is passed to.
 @result	A fully initialized native block object.
 */
- (id)initWithBlock:(id)block signature:(NSMethodSignature *)signature;
@end
