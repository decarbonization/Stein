//
//  STClosure.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STClosure.h"
#import "STEvaluator.h"
#import "STEvaluatorInternal.h"
#import "STList.h"

@implementation STClosure

#pragma mark Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithPrototype:(STList *)prototype forImplementation:(STList *)implementation fromEvaluator:(STEvaluator *)evaluator inScope:(STScope *)superscope
{
	NSParameterAssert(prototype);
	NSParameterAssert(implementation);
	NSParameterAssert(evaluator);
	
	if((self = [super init]))
	{
		mPrototype = prototype;
		mImplementation = implementation;
		mEvaluator = evaluator;
		mSuperscope = superscope;
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Stein Function

- (BOOL)evaluatesOwnArguments
{
	return NO;
}

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)superscope
{
	STScope *scope = [mEvaluator scopeWithEnclosingScope:superscope];
	NSUInteger index = 0;
	NSUInteger countOfArguments = [arguments count];
	for (id name in mPrototype)
	{
		if(index >= countOfArguments)
			[scope setValue:STNull forVariableNamed:name searchParentScopes:NO];
		else
			[scope setValue:[arguments objectAtIndex:index] forVariableNamed:name searchParentScopes:NO];
		index++;
	}
	
	if(mSuperclass)
		[scope setValue:mSuperclass forVariableNamed:kSTEvaluatorSuperclassKey searchParentScopes:NO];
	
	[scope setValue:arguments forVariableNamed:@"_arguments" searchParentScopes:NO];
	
	id result = nil;
	for (id expression in mImplementation)
		result = __STEvaluateExpression(mEvaluator, expression, scope);
	
	return result;
}

#pragma mark -
#pragma mark Properties

@synthesize evaluator = mEvaluator;
@synthesize superscope = mSuperscope;
@synthesize superclass = mSuperclass;
@synthesize name = mName;

#pragma mark -

@synthesize closureSignature = mClosureSignature;
@synthesize prototype = mPrototype;
@synthesize implementation = mImplementation;

#pragma mark -
#pragma mark Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[STClosure class]])
	{
		return ([self.prototype isEqualTo:[object prototype]] && 
				[self.implementation isEqualTo:[object implementation]] && 
				[self.closureSignature isEqualTo:[object closureSignature]]);
	}
	
	return [super isEqualTo:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@ (%@)>", [self className], self, mName ?: @"[Anonymous]", [mPrototype.allObjects componentsJoinedByString:@" "]];
}

#pragma mark -
#pragma mark Exception Handling

- (BOOL)onException:(STClosure *)closure
{
	@try
	{
		STFunctionApply(self, [STList list]);
	}
	@catch (id e)
	{
		STList *arguments = [STList list];
		[arguments addObject:e];
		STFunctionApply(closure, arguments);
		
		return YES;
	}
	
	return NO;
}

@end
