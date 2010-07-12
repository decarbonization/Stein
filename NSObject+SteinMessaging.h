//
//  NSObject+SteinMessaging.h
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

/*!
 @abstract		The SteinMessaging category on NSObject makes all instances of
				NSObject conform to the STFunction protocol.
 @discussion	When an NSObject is applied as a function, the arguments of the function
				are interpreted as the components of a message.
 */
@interface NSObject (SteinMessaging)

@end
