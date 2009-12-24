//
//  STEmbeddedCodeSequences.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STStringWithCode.h"

#import "STList.h"
#import "STEvaluator.h"

@implementation STStringWithCode

#pragma mark Destruction

- (void)dealloc
{
	[mCodeExpressions release];
	mCodeExpressions = nil;
	
	[mCodeRanges release];
	mCodeRanges = nil;
	
	[mString release];
	mString = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Creation

- (id)init
{
	if((self = [super init]))
	{
		mCodeRanges = [NSMutableArray new];
		mCodeExpressions = [NSMutableArray new];
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Properties

@synthesize string = mString;

#pragma mark -
#pragma mark Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[self class]])
	{
		STStringWithCode *otherStringWithCode = object;
		return ([mString isEqualTo:otherStringWithCode->mString] && 
				[mCodeRanges isEqualTo:otherStringWithCode->mCodeRanges] && 
				[mCodeExpressions isEqualTo:otherStringWithCode->mCodeExpressions]);
	}
	else if([object isKindOfClass:[NSString class]])
	{
		return [mString isEqualTo:object];
	}
	
	return [super isEqualTo:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@>", [self className], self, mString];
}

- (NSString *)prettyDescription
{
	return mString;
}

#pragma mark -
#pragma mark Adding Ranges

- (void)addExpression:(id)expression inRange:(NSRange)range
{
	NSParameterAssert(expression);
	
	[mCodeExpressions addObject:expression];
	[mCodeRanges addObject:[NSValue valueWithRange:range]];
}

#pragma mark -
#pragma mark Application

- (id)applyWithEvaluator:(STEvaluator *)evaluator scope:(NSMutableDictionary *)scope
{
	NSParameterAssert(evaluator);
	
	NSMutableString *evaluatedString = [NSMutableString stringWithString:mString];
	
	NSMutableDictionary *evaluationScope = [evaluator scopeWithEnclosingScope:scope];
	for (NSInteger index = [mCodeRanges count] - 1; index >= 0; index--)
	{
		NSRange range = [[mCodeRanges objectAtIndex:index] rangeValue];
		id expression = [mCodeExpressions objectAtIndex:index];
		
		id resultOfExpression = [evaluator evaluateExpression:expression inScope:evaluationScope];
		[evaluatedString replaceCharactersInRange:range withString:[resultOfExpression description]];
	}
	
	return evaluatedString;
}

@end