//
//  NSObject+SteinInternalSupport.h
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>
#import <Stein/STObjectBridge.h>

/*!
 @abstract		The SteinMessaging category on NSObject makes all instances of
				NSObject conform to the STFunction protocol.
 @discussion	When an NSObject is applied as a function, the arguments of the function
				are interpreted as the components of a message.
 */
@interface NSObject (SteinInternalSupport) <STMethodMissing>

#pragma mark -
#pragma mark Ivars

/*!
 @method
 @abstract	Sets the ivar of the receiver specified by a given key to a given value.
 @param		value	The value for the ivar identified by the key.
 @param		name	The name of one of the receiver's ivars. May not be nil.
 */
- (void)setValue:(id)value forIvarNamed:(NSString *)name;
+ (void)setValue:(id)value forIvarNamed:(NSString *)name;

/*!
 @method
 @abstract	Returns the value for the ivar identified by a given key.
 @param		name	The name of one of the receiver's ivars. May not be nil.
 @result	The value for the ivar identified by `name`.
 */
- (id)valueForIvarNamed:(NSString *)name;
+ (id)valueForIvarNamed:(NSString *)name;

@end
