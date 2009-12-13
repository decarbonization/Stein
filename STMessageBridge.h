//
//  STMessageBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>

/*!
 @function
 @abstract		Send a message to an object with a specified selector and a specified array of arguments.
 @param			target		The object to send the message to.
 @param			selector	A selector describing the message to send. May not be nil.
 @param			arguments	The arguments to send along with the message. May not be nil.
 @discussion	If target is nil or NSNull then this method returns NSNull immediately.
 */
ST_EXTERN id STMessageBridgeSend(id target, SEL selector, NSArray *arguments);