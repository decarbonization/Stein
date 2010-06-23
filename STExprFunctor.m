//
//  STExprFunctor.m
//  stein
//
//  Created by Peter MacWhinnie on 6/8/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STExprFunctor.h"
#import "STEvaluator.h"

@implementation STExprFunctor

#pragma mark Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithEvaluator:(STEvaluator *)evaluator
{
	NSParameterAssert(evaluator);
	
	if((self = [super init]))
	{
		mEvaluator = evaluator;
	}
	
	return self;
}

#pragma mark -
#pragma mark Properties

- (BOOL)evaluatesOwnArguments
{
	return YES;
}

- (STEvaluator *)evaluator
{
	return mEvaluator;
}

- (STScope *)superscope
{
	return nil;
}

#pragma mark -
#pragma mark Implementation

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)scope
{
	return STNull;
}

@end
