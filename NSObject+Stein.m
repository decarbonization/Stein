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
#import "STSymbol.h"
#import "STEvaluator.h"

static id EvaluateListOrFunction(id listOrFunction)
{
	//If we've been given nil then we're just going to return nil.
	if(!listOrFunction)
		return nil;
	
	//If we've been given a list, we evaluate it [sort of] like a function.
	if([listOrFunction isKindOfClass:[STList class]])
	{
		STList *list = listOrFunction;
		STEvaluator *evaluator = [list evaluator];
		return [evaluator evaluateExpression:list inScope:nil];
	}
	
	//If we've been given a function, we evaluate it.
	id < STFunction > function = listOrFunction;
	STEvaluator *evaluator = [function evaluator];
	NSMutableDictionary *rootContext = (NSMutableDictionary *)[evaluator rootScope];
	return [function applyWithArguments:[STList list] inScope:rootContext];
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

+ (id)if:(id)thenClause else:(id)elseClause
{
	if([self isTrue])
	{
		return EvaluateListOrFunction(thenClause);
	}
	
	return EvaluateListOrFunction(elseClause);
}

- (id)if:(id)thenClause else:(id)elseClause
{
	if([self isTrue])
	{
		return EvaluateListOrFunction(thenClause);
	}
	
	return EvaluateListOrFunction(elseClause);
}

#pragma mark -

+ (id)if:(id)thenClause
{
	return [self if:thenClause else:nil];
}

- (id)if:(id)thenClause
{
	return [self if:thenClause else:nil];
}

#pragma mark -

+ (id)ifNot:(id)thenClause else:(id)elseClause
{
	if(![self isTrue])
	{
		return EvaluateListOrFunction(thenClause);
	}
	
	return EvaluateListOrFunction(elseClause);
}

- (id)ifNot:(id)thenClause else:(id)elseClause
{
	if(![self isTrue])
	{
		return EvaluateListOrFunction(thenClause);
	}
	
	return EvaluateListOrFunction(elseClause);
}

#pragma mark -

+ (id)ifNot:(id)thenClause
{
	return [self ifNot:thenClause else:nil];
}

- (id)ifNot:(id)thenClause
{
	return [self ifNot:thenClause else:nil];
}

#pragma mark -

- (id)match:(STList *)matchers
{
	STEvaluator *evaluator = matchers.evaluator;
	NSMutableDictionary *scope = [evaluator scopeWithEnclosingScope:nil];
	for (id pair in matchers)
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
