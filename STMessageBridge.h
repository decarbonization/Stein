//
//  STMessageBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>

@class STList;

/*!
 @function
 @abstract		Send a message to an object with a specified selector and a specified array of arguments.
 @param			target		The object to send the message to.
 @param			selector	A selector describing the message to send. May not be nil.
 @param			arguments	The arguments to send along with the message. May not be nil.
 @discussion	If target is nil or NSNull then this method returns NSNull immediately.
 */
ST_EXTERN id STMessageBridgeSend(id target, SEL selector, NSArray *arguments);

/*!
 @function
 @abstract		Send a message to an object's superclass with a specified selector and a specified array of arguments.
 @param			target		The receiver of the meessage.
 @param			superclass	The target superclass. May not be nil.
 @param			selector	A selector describing the message to send. May not be nil.
 @param			arguments	The arguments to send along with the message. May not be nil.
 @discussion	If the target is nil or NSNull then this method returns NSNull immediately.
 */
ST_EXTERN id STMessageBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments);

#pragma mark -

/*!
 @method
 @abstract	Extend an existing class with a specified list of expressions.
 @param		classToExtend	The class to extend. May not be nil. Should implement the NSObject protocol.
 @param		expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
 */
ST_EXTERN void STExtendClass(Class classToExtend, STList *expressions);

/*!
 @method
 @abstract	Define a new class with a specified superclass, and a specified list of expressions.
 @param		subclassName	The name of the subclass to create. May not be nil.
 @param		superclass		The superclass of the new clas. May not be nil. Should be a decendent of NSObject.
 @param		expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
 @result	The new class if it could be created without issue; nil otherwise.
 */
ST_EXTERN Class STDefineClass(NSString *subclassName, Class superclass, STList *expressions);
