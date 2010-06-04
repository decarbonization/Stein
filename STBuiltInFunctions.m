//
//  STBuiltInFunctions.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STBuiltInFunctions.h"

#import "STEvaluator.h"
#import "STScope.h"
#import "STList.h"
#import "STSymbol.h"
#import "STBridgedFunction.h"

#import "STNativeFunctionWrapper.h"
#import "STNativeBlock.h"
#import "STTypeBridge.h"
#import "STPointer.h"
#import <dlfcn.h>

@implementation STBuiltInFunction

#pragma mark Creation

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark -

- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments evaluator:(STEvaluator *)evaluator
{
	NSParameterAssert(implementation);
	NSParameterAssert(evaluator);
	
	if((self = [super init]))
	{
		mImplementation = [implementation copy];
		mEvaluatesOwnArguments = evaluatesOwnArguments;
		mEvaluator = evaluator;
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Function

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)scope
{
	return mImplementation(mEvaluator, arguments, scope);
}

#pragma mark -
#pragma mark Properties

@synthesize implementation = mImplementation;
@synthesize evaluator = mEvaluator;
@synthesize evaluatesOwnArguments = mEvaluatesOwnArguments;

#pragma mark -

- (STScope *)superscope
{
	return nil;
}

@end

#pragma mark -
#pragma mark Mathematical

STBuiltInFunctionDefine(Add, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value += [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Subtract, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value -= [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Multiply, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value *= [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Divide, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value /= [argument doubleValue];
	
	return [NSNumber numberWithDouble:value];
});

STBuiltInFunctionDefine(Modulo, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	long value = [[arguments head] longValue];
	for (id argument in [arguments tail])
		value %= [argument longValue];
	
	return [NSNumber numberWithLong:value];
});

STBuiltInFunctionDefine(Power, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	double value = [[arguments head] doubleValue];
	for (id argument in [arguments tail])
		value = pow(value, [argument doubleValue]);
	
	return [NSNumber numberWithDouble:value];
});

#pragma mark -
#pragma mark Comparisons

STBuiltInFunctionDefine(Equal, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if(![last isEqualTo:argument])
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});
STBuiltInFunctionDefine(NotEqual, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last isEqualTo:argument])
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});

STBuiltInFunctionDefine(LessThan, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] != NSOrderedAscending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});
STBuiltInFunctionDefine(LessThanOrEqual, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] == NSOrderedDescending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});

STBuiltInFunctionDefine(GreaterThan, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	id last = [arguments head];
	for (id argument in [arguments tail])
	{
		if([last compare:argument] != NSOrderedDescending)
			return [NSNumber numberWithBool:NO];
		
		last = argument;
	}
	
	return [NSNumber numberWithBool:YES];
});
STBuiltInFunctionDefine(GreaterThanOrEqual, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
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
#pragma mark Boolean Operations

STBuiltInFunctionDefine(Or, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	BOOL isTrue = STIsTrue([arguments head]);
	if(!isTrue)
	{
		for (id object in [arguments tail])
		{
			isTrue = isTrue || STIsTrue(object);
			if(isTrue)
				break;
		}
	}
	
	return [NSNumber numberWithBool:isTrue];
});

STBuiltInFunctionDefine(And, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	BOOL isTrue = STIsTrue([arguments head]);
	if(isTrue)
	{
		for (id object in [arguments tail])
		{
			isTrue = isTrue && STIsTrue(object);
			if(!isTrue)
				break;
		}
	}
	
	return [NSNumber numberWithBool:isTrue];
});

STBuiltInFunctionDefine(Not, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	return [NSNumber numberWithBool:!STIsTrue([arguments head])];
});

#pragma mark -
#pragma mark Bridging

STBuiltInFunctionDefine(BridgeFunction, YES, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	if([arguments count] < 2)
		STRaiseIssue(arguments.creationLocation, @"bridge-function requires two arguments.");
	
	NSString *symbolName = [[arguments objectAtIndex:0] string];
	NSString *signature = [arguments objectAtIndex:1];
	
	return [[STBridgedFunction alloc] initWithSymbolNamed:symbolName 
												signature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]];
});

STBuiltInFunctionDefine(BridgeConstant, YES, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	if([arguments count] < 2)
		STRaiseIssue(arguments.creationLocation, @"bridge-constant requires two arguments.");
	
	NSString *symbolName = [[arguments objectAtIndex:0] string];
	NSString *signature = [arguments objectAtIndex:1];
	
	void *value = dlsym(RTLD_DEFAULT, [symbolName UTF8String]);
	NSCAssert((value != NULL), @"Could not find constant named %@.", symbolName);
	
	return STTypeBridgeConvertValueOfTypeIntoObject(value, [signature UTF8String]);
});

STBuiltInFunctionDefine(BridgeExtern, YES, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	if([arguments count] < 2)
		STRaiseIssue(arguments.creationLocation, @"extern requires two or more arguments.");
	
	NSString *symbolType = STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string]);
	NSString *symbolName = [[arguments objectAtIndex:1] string];
	
	id result = STNull;
	if([arguments count] == 2)
	{
		void *value = dlsym(RTLD_DEFAULT, [symbolName UTF8String]);
		NSCAssert((value != NULL), @"Could not find constant named %@.", symbolName);
		
		result = STTypeBridgeConvertValueOfTypeIntoObject(value, [symbolType UTF8String]);
	}
	else if([arguments count] == 3)
	{
		NSMutableString *signature = [NSMutableString stringWithString:symbolType];
		for (STSymbol *type in [arguments objectAtIndex:2])
			[signature appendString:STTypeBridgeGetObjCTypeForHumanReadableType([type string])];
		
		result = [[STBridgedFunction alloc] initWithSymbolNamed:symbolName 
													  signature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]];
	}
	
	[evaluator setObject:result forVariableNamed:[arguments objectAtIndex:1] inScope:scope];
	
	return result;
});

STBuiltInFunctionDefine(MakeObjectReference, YES, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	if([arguments count] < 1)
		STRaiseIssue(arguments.creationLocation, @"ref requires an argument.");
	
	STPointer *pointer = [STPointer pointerWithType:@encode(id)];
	[scope setValue:pointer forVariableNamed:[[arguments head] string] searchParentScopes:NO];
	
	return pointer;
});

STBuiltInFunctionDefine(FunctionWrapper, YES, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	if([arguments count] < 3)
		STRaiseIssue(arguments.creationLocation, @"function-wrapper requires 3 arguments.");
	
	NSMutableString *typeString = [NSMutableString stringWithString:STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string])];
	for (STSymbol *type in [arguments objectAtIndex:1])
		[typeString appendString:STTypeBridgeGetObjCTypeForHumanReadableType(type.string)];
	
	NSObject < STFunction > *function = [evaluator evaluateExpression:[arguments objectAtIndex:2] inScope:scope];
	
	return [[STNativeFunctionWrapper alloc] initWithFunction:function 
												   signature:[NSMethodSignature signatureWithObjCTypes:[typeString UTF8String]]];
});

STBuiltInFunctionDefine(WrapBlock, YES, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	if([arguments count] < 3)
		STRaiseIssue(arguments.creationLocation, @"wrap-block requires 3 arguments.");
	
	NSMutableString *typeString = [NSMutableString stringWithString:STTypeBridgeGetObjCTypeForHumanReadableType([[arguments objectAtIndex:0] string])];
	
	//The 'block' parameter.
	[typeString appendString:@"@"];
	
	for (STSymbol *type in [arguments objectAtIndex:1])
		[typeString appendString:STTypeBridgeGetObjCTypeForHumanReadableType(type.string)];
	
	id block = [evaluator evaluateExpression:[arguments objectAtIndex:2] inScope:scope];
	
	return [[STNativeBlock alloc] initWithBlock:block 
									  signature:[NSMethodSignature signatureWithObjCTypes:[typeString UTF8String]]];
});

#pragma mark -
#pragma mark Collection Creation

STBuiltInFunctionDefine(Array, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	return [NSMutableArray arrayWithArray:arguments.allObjects];
});

STBuiltInFunctionDefine(List, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	return [STList listWithList:arguments];
});

STBuiltInFunctionDefine(Dictionary, NO, ^id(STEvaluator *evaluator, STList *arguments, STScope *scope) {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	id key = nil;
	for (id argument in arguments)
	{
		if(!key)
		{
			key = argument;
		}
		else
		{
			if(argument != STNull)
				[dictionary setObject:argument forKey:key];
			
			key = nil;
		}
	}
	
	return dictionary;
});
