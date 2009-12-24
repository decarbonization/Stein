//
//  STEmbeddedCodeSequences.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STEvaluator, STList;
@interface STStringWithCode : NSObject
{
	NSMutableArray *mCodeExpressions;
	NSMutableArray *mCodeRanges;
	NSString *mString;
}
#pragma mark Properties

@property (copy) NSString *string;

#pragma mark -
#pragma mark Adding Ranges

- (void)addExpression:(id)expression inRange:(NSRange)range;

#pragma mark -
#pragma mark Application

- (id)applyWithEvaluator:(STEvaluator *)evaluator scope:(NSMutableDictionary *)scope;

@end
