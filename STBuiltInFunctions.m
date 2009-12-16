//
//  STBuiltInFunctions.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STBuiltInFunctions.h"
#import "STEvaluator.h"
#import "STList.h"
#import "STBridgedFunction.h"

@implementation STBuiltInFunction

- (void)dealloc
{
	[mImplementation release];
	mImplementation = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Creation

- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments evaluator:(STEvaluator *)evaluator
{
	if((self = [super init]))
	{
		mImplementation = [implementation copy];
		mEvaluatesOwnArguments = evaluatesOwnArguments;
		mEvaluator = evaluator;
		
		return self;
	}
	return nil;
}

+ (STBuiltInFunction *)builtInFunctionWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments evaluator:(STEvaluator *)evaluator
{
	return [[[self alloc] initWithImplementation:implementation evaluatesOwnArguments:evaluatesOwnArguments evaluator:evaluator] autorelease];
}

#pragma mark -
#pragma mark Function

- (id)applyWithArguments:(STList *)arguments inScope:(NSMutableDictionary *)scope
{
	return mImplementation(mEvaluator, arguments, scope);
}

#pragma mark -
#pragma mark Properties

@synthesize implementation = mImplementation;
@synthesize evaluator = mEvaluator;
@synthesize evaluatesOwnArguments = mEvaluatesOwnArguments;

@end

#pragma mark -

STBuiltInFunctionDefine(Add, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value += [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Subtract, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value -= [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Multiply, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value *= [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Divide, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value /= [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Modulo, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	long value = [[arguments head] longValue];
	for (id argument in [arguments tail])
		value %= [argument longValue];
	
	return [NSNumber numberWithLong:value];
});

STBuiltInFunctionDefine(Power, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value = pow(value, [argument doubleValue]);
	
	return [NSNumber numberWithDouble:value];
});

#pragma mark -

STBuiltInFunctionDefine(Equal, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if(![last isEqualTo:argument])
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});
STBuiltInFunctionDefine(NotEqual, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last isEqualTo:argument])
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});

STBuiltInFunctionDefine(LessThan, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] != NSOrderedAscending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});
STBuiltInFunctionDefine(LessThanOrEqual, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] == NSOrderedDescending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});

STBuiltInFunctionDefine(GreaterThan, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] != NSOrderedDescending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});
STBuiltInFunctionDefine(GreaterThanOrEqual, NO, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] == NSOrderedAscending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});

#pragma mark -

STBuiltInFunctionDefine(BridgeFunction, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSCAssert(([arguments count] >= 2), @"Expected at least two arguments, got %ld.", [arguments count]);
	
	NSString *symbolName = [[arguments objectAtIndex:0] string];
	NSString *signature = [arguments objectAtIndex:1];
	
	return [[[STBridgedFunction alloc] initWithSymbolNamed:symbolName 
												 signature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]] autorelease];
});
