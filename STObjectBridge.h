//
//  STObjectBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#ifndef STObjectBridge
#define STObjectBridge 1

#import <Cocoa/Cocoa.h>

@class STList, STScope;

///The STMethodMissing protocol defines methods used by the high level
///forwarding mechanism implemented in Stein's object bridge.
///
///The Stein object bridge's forwarding mechanism is considerably higher level than
///the forwarding mechanism provided by the Objective-C runtime. All values are passed
///around as objects, type information is unnecessary. This allows a considerably cleaner
///method of responding to unknown messages in an abstract manner.
///
///This forwarding mechanism is used to implement infix arithmetic on NSNumber.
@protocol STMethodMissing

///Returns whether or not the receiver can handle a missing method with a specified selector.
///
/// \param		selector	The method which contains no known implementation in the receiver.
/// \param		scope		The scope in which the receiver was called from.
/// \result		YES if the receiver can handle the selector; NO otherwise.
///
///This method is invoked by the Stein runtime when an object doesn't respond to a specified selector.
- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector;

///Perform an action for a missing method.
///
/// \param		selector	The method to perform an action for.
/// \param		arguments	The arguments passed to the method.
/// \param		scope		The scope in which the receiver was called from.
/// \result		The result of the action performed.
///
///This method is only called if -[STMethodMissing canHandleMissingMethodWithSelector:inScope:] returns YES. NSObject's default implementation of this method logs an error message and returns STNull.
- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope;

@end

///Send a message to an object with a specified selector and a specified array of arguments.
///
/// \param		target		The object to send the message to.
/// \param		selector	A selector describing the message to send. May not be nil.
/// \param		arguments	The arguments to send along with the message. May not be nil.
///
///If target is nil or STNull then this method returns STNull immediately.
///
///The object bridge messaging mechanism adds two additional routes to find a handler for
///selectors the `target` object does not recognize:
///
///-	First it will append «inEvaluator:» to the end of `selector`, this allows methods that require the evaluator as a parameter to be invoked more cleanly from within Stein.
///-	If this fails, then it will attempt to use the forwarding mechanism defined by STMethodMissing.
///     See the documentation on STMethodMissing for more info.
///-	If the method-missing forwarding mechanism fails to handle the message, then
///     @selector(doesNotRecognizeSelector:) is invoked on target.
ST_EXTERN id STObjectBridgeSend(id target, SEL selector, NSArray *arguments, STScope *scope);

///Send a message to an object's superclass with a specified selector and a specified array of arguments.
///
/// \param		target		The receiver of the meessage.
/// \param		superclass	The target superclass. May not be nil.
/// \param		selector	A selector describing the message to send. May not be nil.
/// \param		arguments	The arguments to send along with the message. May not be nil.
///If the target is nil or STNull then this method returns STNull immediately.
///
///The object bridge messaging mechanism adds two additional routes to find a handler for
///selectors the `target` object does not recognize:
///
///-	First it will append «inEvaluator:» to the end of `selector`, this allows methods that require the evaluator as a parameter to be invoked more cleanly from within Stein.
///-	If this fails, then it will attempt to use the forwarding mechanism defined by STMethodMissing.
///     See the documentation on STMethodMissing for more info.
///-	If the method-missing forwarding mechanism fails to handle the message, then
///     @selector(doesNotRecognizeSelector:) is invoked on target.
ST_EXTERN id STObjectBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments, STScope *scope);

#pragma mark -

///Extend an existing class with a specified list of expressions.
///
/// \param	classToExtend	The class to extend. May not be nil. Should implement the NSObject protocol.
/// \param	expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
ST_EXTERN void STExtendClass(Class classToExtend, STList *expressions);

#pragma mark -

///Undefine a class in the ObjC runtime.
ST_EXTERN BOOL STUndefineClass(Class classToUndefine, STScope *scope);

///Define a new class with a specified superclass, and a specified list of expressions.
///
/// \param	subclassName	The name of the subclass to create. May not be nil.
/// \param	superclass		The superclass of the new clas. May not be nil. Should be a decendent of NSObject.
/// \param	expressions		A list of expressions consisting of method declarations, and decorators. May not be nil.
/// \result	The new class if it could be created without issue; nil otherwise.
ST_EXTERN Class STDefineClass(NSString *subclassName, Class superclass, STList *expressions, STScope *scope);

#endif /* STObjectBridge */
