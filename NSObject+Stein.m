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

+ (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause
{
	if([self isTrue])
	{
		return STFunctionApply(thenClause, [STList list]);
	}
	
	return STFunctionApply(elseClause, [STList list]);
}

- (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause
{
	if([self isTrue])
	{
		return STFunctionApply(thenClause, [STList list]);
	}
	
	return STFunctionApply(elseClause, [STList list]);
}

#pragma mark -

+ (id)ifTrue:(id < STFunction >)thenClause
{
	return [self ifTrue:thenClause ifFalse:nil];
}

- (id)ifTrue:(id < STFunction >)thenClause
{
	return [self ifTrue:thenClause ifFalse:nil];
}

#pragma mark -

+ (id)ifFalse:(id < STFunction >)thenClause ifTrue:(id < STFunction >)elseClause
{
	if(![self isTrue])
	{
		return STFunctionApply(thenClause, [STList list]);
	}
	
	return STFunctionApply(elseClause, [STList list]);
}

- (id)ifFalse:(id < STFunction >)thenClause ifTrue:(id < STFunction >)elseClause
{
	if(![self isTrue])
	{
		return STFunctionApply(thenClause, [STList list]);
	}
	
	return STFunctionApply(elseClause, [STList list]);
}

#pragma mark -

+ (id)ifFalse:(id < STFunction >)thenClause
{
	return [self ifFalse:thenClause ifTrue:nil];
}

- (id)ifFalse:(id < STFunction >)thenClause
{
	return [self ifFalse:thenClause ifTrue:nil];
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

#pragma mark -

@implementation NSArray (Stein)

- (void)foreach:(STClosure *)closure
{
	for (id object in self)
	{
		STFunctionApply(closure, [STList listWithObject:object]);
	}
}

- (NSArray *)map:(STClosure *)closure
{
	NSMutableArray *objects = [NSMutableArray array];
	
	for (id object in self)
	{
		id mappedObject = STFunctionApply(closure, [STList listWithObject:object]);
		if(!mappedObject)
			break;
		
		[objects addObject:mappedObject];
	}
	
	return objects;
}

- (NSArray *)filter:(STClosure *)closure
{
	NSMutableArray *objects = [NSMutableArray array];
	
	for (id object in self)
	{
		if([STFunctionApply(closure, [STList listWithObject:object]) isTrue])
			[objects addObject:object];
	}
	
	return objects;
}

@end

@implementation NSSet (Stein)

- (void)foreach:(STClosure *)closure
{
	for (id element in self)
	{
		STFunctionApply(closure, [STList listWithObject:element]);
	}
}

- (NSSet *)map:(STClosure *)closure
{
	NSMutableSet *objects = [NSMutableSet set];
	
	for (id object in self)
	{
		id mappedObject = STFunctionApply(closure, [STList listWithObject:object]);
		if(!mappedObject)
			break;
		
		[objects addObject:mappedObject];
	}
	
	return objects;
}

- (NSSet *)filter:(STClosure *)closure
{
	NSMutableSet *objects = [NSMutableSet set];
	
	for (id object in self)
	{
		if([STFunctionApply(closure, [STList listWithObject:object]) isTrue])
			[objects addObject:object];
	}
	
	return objects;
}

@end
