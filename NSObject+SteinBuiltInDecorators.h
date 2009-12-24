//
//  NSObject+SteinBuiltInDecorators.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/24.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 @class
 @abstract	This category on NSObject defines the built in decorators for the Stein programming language.
 */
@interface NSObject (SteinBuiltInDecorators)

#pragma mark Conformance

/*!
 @method
 @abstract	Specify that a class implements a collection of protocols.
 */
+ (void)implements:(NSObject < NSFastEnumeration > *)protocols;

#pragma mark -
#pragma mark Properties

/*!
 @method
 @abstract	Synthesize an accessor/mutator pair for a specified ivar.
 */
+ (void)synthesize:(id)ivarName;

/*!
 @method
 @abstract	Synthesize an accessor for a specified ivar.
 */
+ (void)synthesizeReadOnly:(id)ivarName;

/*!
 @method
 @abstract	Synthesize a mutator for a specified ivar.
 */
+ (void)synthesizeWriteOnly:(id)ivarName;

@end
