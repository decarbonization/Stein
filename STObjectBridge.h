//
//  STObjectBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>

@class STList, STEvaluator;

/*!
 @function
 @abstract		Send a message to an object with a specified selector and a specified array of arguments.
 @param			target		The object to send the message to.
 @param			selector	A selector describing the message to send. May not be nil.
 @param			arguments	The arguments to send along with the message. May not be nil.
 @discussion	If target is nil or STNull then this method returns STNull immediately.
				
				The object bridge messaging mechanism adds two additional routes to find a handler for
				selectors the `target` object does not recognize:
 
				-	First it will append «inEvaluator:» to the end of `selector`, this allows methods that require the evaluator as a parameter to be invoked more cleanly from within Stein.
				-	If this fails, then it will attempt to use the forwarding mechanism defined by STMethodMissing.
					See the documentation on STMethodMissing for more info.
				-	If the method-missing forwarding mechanism fails to handle the message, then
					@selector(doesNotRecognizeSelector:) is invoked on target.
 */
ST_EXTERN id STObjectBridgeSend(id target, SEL selector, NSArray *arguments, STEvaluator *evaluator);

/*!
 @function
 @abstract		Send a message to an object's superclass with a specified selector and a specified array of arguments.
 @param			target		The receiver of the meessage.
 @param			superclass	The target superclass. May not be nil.
 @param			selector	A selector describing the message to send. May not be nil.
 @param			arguments	The arguments to send along with the message. May not be nil.
 @discussion	If the target is nil or STNull then this method returns STNull immediately.
				
				The object bridge messaging mechanism adds two additional routes to find a handler for
				selectors the `target` object does not recognize:
 
				-	First it will append «inEvaluator:» to the end of `selector`, this allows methods that require the evaluator as a parameter to be invoked more cleanly from within Stein.
				-	If this fails, then it will attempt to use the forwarding mechanism defined by STMethodMissing.
					See the documentation on STMethodMissing for more info.
				-	If the method-missing forwarding mechanism fails to handle the message, then
					@selector(doesNotRecognizeSelector:) is invoked on target.
 */
ST_EXTERN id STObjectBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments, STEvaluator *evaluator);

#pragma mark -

/*!
 @function
 @abstract	Extend an existing class with a specified list of expressions.
 @param		classToExtend	The class to extend. May not be nil. Should implement the NSObject protocol.
 @param		expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
 */
ST_EXTERN void STExtendClass(Class classToExtend, STList *expressions, STEvaluator *evaluator);

#pragma mark -

/*!
 @function
 @abstract	Undefine a class in the ObjC runtime.
 */
ST_EXTERN BOOL STUndefineClass(Class classToUndefine, STEvaluator *evaluator);

/*!
 @function
 @abstract	Remove a classes method, protocol, and property information. This effectively returns a class to a blank-slate like condition.
 */
ST_EXTERN BOOL STResetClass(Class classToReset, STEvaluator *evaluator);

/*!
 @function
 @abstract	Define a new class with a specified superclass, and a specified list of expressions.
 @param		subclassName	The name of the subclass to create. May not be nil.
 @param		superclass		The superclass of the new clas. May not be nil. Should be a decendent of NSObject.
 @param		expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
 @result	The new class if it could be created without issue; nil otherwise.
 */
ST_EXTERN Class STDefineClass(NSString *subclassName, Class superclass, STList *expressions, STEvaluator *evaluator);
