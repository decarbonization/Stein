//
//  STClosure.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ffi/ffi.h>
#import <Stein/STFunction.h>

@class STEvaluator, STList;

/*!
 @class
 @abstract	The STClosure class is responsible for representing closures and functions in Stein.
 */
@interface STClosure : NSObject < STFunction >
{
	/* weak */		STEvaluator *mEvaluator;
	/* strong */	NSMutableDictionary *mSuperscope;
	
	//Closure Description
	/* strong */	NSMethodSignature *mClosureSignature;
	/* strong */	STList *mPrototype;
	/* strong */	STList *mImplementation;
	
	//Foreign Function Interface
	/* auto */		ffi_cif *mFFIClosureInformation;
	
	/* weak */		ffi_type *mFFIReturnType;
	/* auto */		ffi_type **mFFIArgumentTypes;
	
	/* owner*/		ffi_closure *mFFIClosure;
}

/*!
 @method
 @abstract		Initialize a Stein closure with a prototype, implementation, a signature describing it's prototype, and an evaluator to apply it with.
 @param			prototype		The prototype of the closure in the form of an STList of symbols. May not be nil.
 @param			implementation	The implementation of the closure in the form of an STList of Stein expressions. May not be nil.
 @param			signature		A method signature object describing the types of the names in prototype as well as the return type of the closure.
 @param			evaluator		The evaluator to use when applying the closure.
 @param			superscope		The scope that encloses the closure being created.
 @result		A fully initialized Stein closure object ready for use.
 @discussion	This is the designated initializer of STClosure.
 */
- (id)initWithPrototype:(STList *)prototype forImplementation:(STList *)implementation withSignature:(NSMethodSignature *)signature fromEvaluator:(STEvaluator *)evaluator inScope:(NSMutableDictionary *)superscope;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract		The closure's native function pointer suitable for use anywhere a function pointer is expected.
 @discussion	Only closure's who have had type signature's specified can produce a valid function pointer.
 */
@property (readonly) void *functionPointer;

#pragma mark -

/*!
 @property
 @abstract	The evaluator to use when the closure is applied.
 */
@property (readonly) STEvaluator *evaluator;

/*!
 @property
 @abstract	The superscope of the closure.
 */
@property (readonly) NSMutableDictionary *superscope;

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
@end
