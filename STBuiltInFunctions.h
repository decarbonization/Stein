//
//  STBuiltInFunctions.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

#pragma once

@class STScope;

/*!
 @defined
 @abstract	Export a built in function for use with STEvaluator. For use with STBuiltInFunctionDefine.
 */
#define STBuiltInFunctionExport(name) ST_EXTERN STBuiltInFunction *STBuiltInFunction##name(STEvaluator *evaluator)

/*!
 @defined
 @abstract	Define a built in function for use with STEvaluator.
 @param		name					The name of the built in.
 @param		evaluatesOwnArguments	Whether or not the built in intends to evaluate its arguments on its own time.
 @param		...						A block object to use for implementation.
 */
#define STBuiltInFunctionDefine(name, evaluates, ...) STBuiltInFunction *STBuiltInFunction##name(STEvaluator *evaluator) \
{ \
	return [[STBuiltInFunction alloc] initWithImplementation:(__VA_ARGS__) evaluatesOwnArguments:evaluates evaluator:evaluator]; \
}

/*!
 @defined
 @abstract	Look up a built in function by name for use with a specified evaluator.
 @param		name		The name of the built in.
 @param		evaluator	The evaluator to associate the returned value with.
 */
#define STBuiltInFunctionWithNameForEvaluator(name, evaluator) STBuiltInFunction##name(evaluator)

#pragma mark -

@class STEvaluator, STList;

/*!
 @typedef
 @abstract	The block type used to provide implementations for STBuiltInFunction objects.
 @param		evaluator	The evaluator that owns the built in function.
 @param		arguments	The arguments that were given to the function when it was applied.
 @param		scope		The scope in which the function was called in.
 */
typedef id(^STBuiltInFunctionImplementation)(STEvaluator *evaluator, STList *arguments, STScope *scope);

/*!
 @class
 @abstract	The STBuiltInFunction is used to represent built in functions in the Stein programming language.
 */
@interface STBuiltInFunction : NSObject < STFunction >
{
	/* owner */	STBuiltInFunctionImplementation mImplementation;
	/* weak */	STEvaluator *mEvaluator;
	/* n/a */	BOOL mEvaluatesOwnArguments;
}
#pragma mark Creation

/*!
 @method
 @abstract	Initialize the receiver with an implementation block, and an evaluator.
 @param		implementation			A block to copy that describes the receiver's implementation. May not be nil.
 @param		evaluatesOwnArguments	Whether or not the receiver is going to evaluate it's own arguments when it's applied.
 @param		evaluator				The evaluator that owns the built in function. May not be nil.
 @result	A fully initialized built in function object.
 */
- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation 
	   evaluatesOwnArguments:(BOOL)evaluatesOwnArguments 
				   evaluator:(STEvaluator *)evaluator;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The implementation of the built in function.
 */
@property (readonly, copy) STBuiltInFunctionImplementation implementation;

/*!
 @property
 @abstract	The evaluator the built in function is associated with.
 */
@property (readonly) STEvaluator *evaluator;

/*!
 @property
 @abstract	Whether or not the built in function intends to evaluate the arguments its given during application itself.
 */
@property (readonly) BOOL evaluatesOwnArguments;
@end

#pragma mark -
#pragma mark Basic Math

//The implementation of the + operator.
STBuiltInFunctionExport(Add);

//The implementation of the - operator.
STBuiltInFunctionExport(Subtract);

//The implementation of the * operator.
STBuiltInFunctionExport(Multiply);

//The implementation of the / operator.
STBuiltInFunctionExport(Divide);

//The implementation of the % operator.
STBuiltInFunctionExport(Modulo);

//The implementation of the ** operator.
STBuiltInFunctionExport(Power);

#pragma mark -
#pragma mark Comparisons

//The implementation of the = operator.
STBuiltInFunctionExport(Equal);
//The implementation of the ≠ operator.
STBuiltInFunctionExport(NotEqual);

//The implementation of the < operator.
STBuiltInFunctionExport(LessThan);

//The implementation of the ≤ operator.
STBuiltInFunctionExport(LessThanOrEqual);

//The implementation of the > operator.
STBuiltInFunctionExport(GreaterThan);

//The implementation of the ≥ operator.
STBuiltInFunctionExport(GreaterThanOrEqual);

#pragma mark -
#pragma mark Logical Operations

//The implementation of the || operator.
STBuiltInFunctionExport(Or);
//The implementation of the && operator.
STBuiltInFunctionExport(And);

//The implementation of the 'not' operator.
STBuiltInFunctionExport(Not);

#pragma mark -
#pragma mark Bridging

//The implementation of the bridge-function generator.
STBuiltInFunctionExport(BridgeFunction);

//The implementation of the bridge-constant generator.
STBuiltInFunctionExport(BridgeConstant);

//The implementation of the 'extern' operator.
STBuiltInFunctionExport(BridgeExtern);

//The implementation of the 'ref' operator.
STBuiltInFunctionExport(MakeObjectReference);

//The implementation of the 'function-wrapper' generator.
STBuiltInFunctionExport(FunctionWrapper);

//The implementation of the 'wrap-block' generator.
STBuiltInFunctionExport(WrapBlock);

#pragma mark -
#pragma mark Collection Creation

//The implementation of the array function.
STBuiltInFunctionExport(Array);

//The implementation of the list function.
STBuiltInFunctionExport(List);

//The implementation of the dict function.
STBuiltInFunctionExport(Dictionary);
