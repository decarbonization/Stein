//
//  STObjectBridge.h
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
 @discussion	If target is nil or STNull then this method returns STNull immediately.
				
				This function invokes the missing method handling system defined in NSObject+Stein.
 */
ST_EXTERN id STObjectBridgeSend(id target, SEL selector, NSArray *arguments);

/*!
 @function
 @abstract		Send a message to an object's superclass with a specified selector and a specified array of arguments.
 @param			target		The receiver of the meessage.
 @param			superclass	The target superclass. May not be nil.
 @param			selector	A selector describing the message to send. May not be nil.
 @param			arguments	The arguments to send along with the message. May not be nil.
 @discussion	If the target is nil or STNull then this method returns STNull immediately.
				
				This function _does not_ invoke the missing method handling system defined in NSObject+Stein.
 */
ST_EXTERN id STObjectBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments);

#pragma mark -

/*!
 @function
 @abstract	Extend an existing class with a specified list of expressions.
 @param		classToExtend	The class to extend. May not be nil. Should implement the NSObject protocol.
 @param		expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
 */
ST_EXTERN void STExtendClass(Class classToExtend, STList *expressions);

#pragma mark -

/*!
 @function
 @abstract	Undefine a class in the ObjC runtime.
 */
ST_EXTERN BOOL STUndefineClass(Class classToUndefine);

/*!
 @function
 @abstract	Remove a classes method, protocol, and property information. This effectively returns a class to a blank-slate like condition.
 */
ST_EXTERN BOOL STResetClass(Class classToReset);

/*!
 @function
 @abstract	Define a new class with a specified superclass, and a specified list of expressions.
 @param		subclassName	The name of the subclass to create. May not be nil.
 @param		superclass		The superclass of the new clas. May not be nil. Should be a decendent of NSObject.
 @param		expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
 @result	The new class if it could be created without issue; nil otherwise.
 */
ST_EXTERN Class STDefineClass(NSString *subclassName, Class superclass, STList *expressions);
