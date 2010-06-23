//
//  STExprFunctor.h
//  stein
//
//  Created by Peter MacWhinnie on 6/8/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "STFunction.h"

/*!
 @abstract	The STExprFunctor class is the concrete implementation of the `expr`
			function that provides the infix mathematical construct for Stein.
 */
@interface STExprFunctor : NSObject < STFunction >
{
	STEvaluator *mEvaluator;
}

#pragma mark Initialization

/*!
 @abstract		Initialize the receiver with a specified evaluator object.
 @param			evaluator	The evaluator the receiver will use when applying expressions. Required.
 @result		A fully initialized expr functor object.
 @discussion	This is the designated initializer of the STExprFunctor class.
 */
- (id)initWithEvaluator:(STEvaluator *)evaluator;

@end
