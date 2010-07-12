//
//  STClosure.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

@class STList, STScope;

/*!
 @class
 @abstract	The STClosure class is responsible for representing closures and functions in Stein.
 */
@interface STClosure : NSObject < STFunction >
{
	STScope *mSuperscope;
	Class mSuperclass;
	NSString *mName;
	
	//Closure Description
	STList *mPrototype;
	STList *mImplementation;
}

/*!
 @method
 @abstract		Initialize a Stein closure with a prototype, implementation, and a signature describing it's prototype.
 @param			prototype		The prototype of the closure in the form of an STList of symbols. May not be nil.
 @param			implementation	The implementation of the closure in the form of an STList of Stein expressions. May not be nil.
 @param			superscope		The scope that encloses the closure being created.
 @result		A fully initialized Stein closure object ready for use.
 @discussion	This is the designated initializer of STClosure.
 */
- (id)initWithPrototype:(STList *)prototype forImplementation:(STList *)implementation inScope:(STScope *)superscope;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The superscope of the closure.
 */
@property (readonly) STScope *superscope;

/*!
 @property
 @abstract		This property is provided for closures that serve as the implementation for methods.
 @discussion	When this property is set, the closure will set a value for the key kSTEvaluatorSuperclassKey
				in it's scope. This allows the super function to be used.
 */
@property (assign) Class superclass;

/*!
 @property
 @abstract		The name of the closure.
 @discussion	This is typically set by the function operator.
 */
@property (copy) NSString *name;

#pragma mark -

/*!
 @property
 @abstract	A method signature object describing the closure's arguments and return type.
 */
@property (readonly) NSMethodSignature *closureSignature;

/*!
 @property
 @abstract	An STList of symbols describing the closure's arguments.
 */
@property (readonly) STList *prototype;

/*!
 @property
 @abstract	An STList of expressions describing the closure's implementation.
 */
@property (readonly) STList *implementation;

#pragma mark -
#pragma mark Exception Handling

/*!
 @method
 @abstract	Invoke the receiver in the context of a try..catch block, invoking a specified block if an exception occurs.
 @param		closure		The closure to invoke if an exception is raised while evaluating the receiver.
 @result	YES if an exception was raised while evaluating the receiver; NO otherwise.
 */
- (BOOL)onException:(STClosure *)closure;

@end
