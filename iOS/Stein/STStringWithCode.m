//
//  STEmbeddedCodeSequences.m
//  stein
//
//  Created by Kevin MacWhinnie on 09/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STStringWithCode.h"

#import "STList.h"
#import "STInterpreter.h"

@implementation STStringWithCode

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

#pragma mark - Properties

@synthesize string = mString;

#pragma mark - Identity

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[self class]])
	{
		STStringWithCode *otherStringWithCode = object;
		return ([mString isEqual:otherStringWithCode->mString] && 
				[mCodeRanges isEqual:otherStringWithCode->mCodeRanges] && 
				[mCodeExpressions isEqual:otherStringWithCode->mCodeExpressions]);
	}
	else if([object isKindOfClass:[NSString class]])
	{
		return [mString isEqual:object];
	}
	
	return [super isEqual:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@>", [self className], self, mString];
}

- (NSString *)prettyDescription
{
	return mString;
}

#pragma mark - Adding Ranges

- (void)addExpression:(id)expression inRange:(NSRange)range
{
	NSParameterAssert(expression);
	
	[mCodeExpressions addObject:expression];
	[mCodeRanges addObject:[NSValue valueWithRange:range]];
}

#pragma mark - Application

- (id)applyInScope:(STScope *)scope
{
	STScope *expressionEvaluationScope = [STScope scopeWithParentScope:scope];
	
	NSMutableArray *evaluatedExpressionStrings = [NSMutableArray array];
	for (id expression in mCodeExpressions)
	{
		id resultOfExpression = STEvaluate(expression, expressionEvaluationScope);
		[evaluatedExpressionStrings addObject:[resultOfExpression description]];
	}
	
	NSMutableString *resultString = [NSMutableString stringWithString:mString];
	[mCodeRanges enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSValue *value, NSUInteger index, BOOL *stop) {
		NSRange range = [value rangeValue];
		[resultString replaceCharactersInRange:range 
									withString:[evaluatedExpressionStrings objectAtIndex:index]];
	}];
	
	return resultString;
}

@end
