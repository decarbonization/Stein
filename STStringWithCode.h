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
 @abstract	Apply the receiver within a specified scope.
 */
- (id)applyInScope:(STScope *)scope;

@end
