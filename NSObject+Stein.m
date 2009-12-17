//
//  NSObject+Stein.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSObject+Stein.h"
#import "STFunction.h"
#import "STList.h"
#import "STClosure.h"
#import "STSymbol.h"
#import "STEvaluator.h"

ST_INLINE id ApplyFunction(id < STFunction > function)
{
	STEvaluator *evaluator = [function evaluator];
	NSMutableDictionary *scope = [evaluator scopeWithEnclosingScope:nil];
	
	return [function applyWithArguments:[STList list] inScope:scope];
}

@implementation NSObject (Stein)

#pragma mark Truthiness

+ (BOOL)isTrue
{
	return YES;
}

- (BOOL)isTrue
{
	return YES;
}

#pragma mark -
#pragma mark Control Flow

+ (id)if:(id < STFunction >)thenClause else:(id < STFunction >)elseClause
{
	if([self isTrue])
	{
		return ApplyFunction(thenClause);
	}
	
	return ApplyFunction(elseClause);
}

- (id)if:(id < STFunction >)thenClause else:(id < STFunction >)elseClause
{
	if([self isTrue])
	{
		return ApplyFunction(thenClause);
	}
	
	return ApplyFunction(elseClause);
}

#pragma mark -

+ (id)if:(id < STFunction >)thenClause
{
	return [self if:thenClause else:nil];
}

- (id)if:(id < STFunction >)thenClause
{
	return [self if:thenClause else:nil];
}

#pragma mark -

+ (id)ifNot:(id < STFunction >)thenClause else:(id < STFunction >)elseClause
{
	if(![self isTrue])
	{
		return ApplyFunction(thenClause);
	}
	
	return ApplyFunction(elseClause);
}

- (id)ifNot:(id < STFunction >)thenClause else:(id < STFunction >)elseClause
{
	if(![self isTrue])
	{
		return ApplyFunction(thenClause);
	}
	
	return ApplyFunction(elseClause);
}

#pragma mark -

+ (id)ifNot:(id < STFunction >)thenClause
{
	return [self ifNot:thenClause else:nil];
}

- (id)ifNot:(id < STFunction >)thenClause
{
	return [self ifNot:thenClause else:nil];
}

#pragma mark -

- (id)match:(STClosure *)matchers
{
	STEvaluator *evaluator = matchers.evaluator;
	NSMutableDictionary *scope = [evaluator scopeWithEnclosingScope:nil];
	for (id pair in matchers.implementation)
	{
		if(![pair isKindOfClass:[STList class]])
			continue;
		
		id unevaluatedObjectToMatch = [pair head];
		if([unevaluatedObjectToMatch isEqualTo:[STSymbol symbolWithString:@"_"]])
			return [evaluator evaluateExpression:[pair tail] inScope:scope];
			
		if([self isEqualTo:[evaluator evaluateExpression:unevaluatedObjectToMatch inScope:scope]])
			return [evaluator evaluateExpression:[pair tail] inScope:scope];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Printing

- (NSString *)print
{
	NSString *description = [self description];
	
	puts([description UTF8String]);
	
	return description;
}

@end

#pragma mark -

@implementation NSNumber (Stein)

- (BOOL)isTrue
{
	return [self boolValue];
}

@end

#pragma mark -

@implementation NSNull (Stein)

+ (BOOL)isTrue
{
	return NO;
}

- (BOOL)isTrue
{
	return NO;
}

@end
