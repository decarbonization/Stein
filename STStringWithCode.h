//
//  STEmbeddedCodeSequences.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STList, STScope;

///The STStringWithCode class is used to represent a string that has code
///interpolated within its contents in the Stein programming language.

@interface STStringWithCode : NSObject
{
	NSMutableArray *mCodeExpressions;
	NSMutableArray *mCodeRanges;
	NSString *mString;
}
#pragma mark Properties

///The string.
@property (copy) NSString *string;

#pragma mark - Adding Ranges

///Add a specified expression value to be substituted for a specified range.
///
/// \param	expression	The expression to be substituted. May not be nil.
/// \param	range		The range to substitute the expression into.
- (void)addExpression:(id)expression inRange:(NSRange)range;

#pragma mark - Application

///Apply the receiver within a specified scope.
- (id)applyInScope:(STScope *)scope;

@end
