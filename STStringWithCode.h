//
//  STEmbeddedCodeSequences.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STEvaluator, STList, STScope;

/*!
 @class
 @abstract	The STStringWithCode class is used to represent a string that has code
			interpolated within its contents in the Stein programming language.
 */
@interface STStringWithCode : NSObject
{
	/* owner */	NSMutableArray *mCodeExpressions;
	/* owner */	NSMutableArray *mCodeRanges;
	/* owner */	NSString *mString;
}
#pragma mark Properties

/*!
 @property
 @abstract	The string.
 */
@property (copy) NSString *string;

#pragma mark -
#pragma mark Adding Ranges

/*!
 @method
 @abstract	Add a specified expression value to be substituted for a specified range.
 @param		expression	The expression to be substituted. May not be nil.
 @param		range		The range to substitute the expression into.
 */
- (void)addExpression:(id)expression inRange:(NSRange)range;

#pragma mark -
#pragma mark Application

/*!
 @method
 @abstract		Apply the receiver with a specified evaluator within a specified scope.
 @param			evaluator	The evaluator to use when evaluating the receiver's expressions. May not be nil.
 @param			scope		The scope to evaluate the expressions in. May be nil.
 @result		A string with the result of the receiver's expressions embedded within it's contents.
 @discussion	The receiver's expressions will be evaluated within a unique scope.
 */
- (NSString *)applyWithEvaluator:(STEvaluator *)evaluator scope:(STScope *)scope;

@end
