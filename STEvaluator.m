//
//  STEvaluator.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STEvaluator.h"
#import "STParser.h"

#import "STSymbol.h"
#import "STList.h"

#import "STFunction.h"
#import "STClosure.h"
#import "STMessageBridge.h"

#import "STBuiltInFunctions.h"

NSString *const kSTEvaluatorEnclosingScopeKey = @"$__enclosingScope";

static STList *EvaluateArgumentList(STEvaluator *self, STList *arguments, NSMutableDictionary *scope);
static id SendMessageWithTargetAndArguments(STEvaluator *self, id target, STList *arguments, NSMutableDictionary *scope);
static id EvaluateList(STEvaluator *self, STList *list, NSMutableDictionary *scope);
static id EvaluateExpression(STEvaluator *self, id expression, NSMutableDictionary *scope);

#pragma mark -
#pragma mark Core Built Ins

STBuiltInFunctionDefine(Set, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSCAssert(([arguments count] >= 2), 
			  @"Wrong number of arguments given to set, expected 2 got %ld.", [arguments count]);
	
	NSString *key = [[arguments objectAtIndex:0] string];
	id value = EvaluateExpression(evaluator, [arguments objectAtIndex:1], scope);
	[scope setValue:value forKey:key];
	
	return value;
});

STBuiltInFunctionDefine(Lambda, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSCAssert(([arguments count] >= 2), 
			  @"Wrong number of arguments given to lambda, expected at least 2, got %ld.", [arguments count]);
	
	NSString *signature = nil;
	STList *parameterList = nil;
	STList *implementation = nil;
	
	id first = [arguments objectAtIndex:0];
	if([first isKindOfClass:[NSString class]])
	{
		signature = first;
		parameterList = [arguments objectAtIndex:1];
		implementation = [STList listWithList:[arguments objectAtIndex:2]];
	}
	else
	{
		parameterList = first;
		implementation = [STList listWithList:[arguments objectAtIndex:1]];
		
		NSMutableString *signatureInProgress = [NSMutableString stringWithString:@"@"];
		for (NSUInteger index = 0; index < [parameterList count]; index++)
			[signatureInProgress appendString:@"@"];
		
		signature = signatureInProgress;
	}
	implementation.isQuoted = NO;
	
	return [[[STClosure alloc] initWithPrototype:parameterList
							   forImplementation:implementation
								   withSignature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]
								   fromEvaluator:evaluator 
										 inScope:scope] autorelease];
});

STBuiltInFunctionDefine(Function, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	NSCAssert(([arguments count] >= 3), 
			  @"Wrong number of arguments given to lambda, expected at least 3, got %ld.", [arguments count]);
	
	NSString *signature = nil;
	STList *parameterList = nil;
	STList *implementation = nil;
	
	id firstValueInDefinition = [arguments objectAtIndex:1];
	if([firstValueInDefinition isKindOfClass:[NSString class]])
	{
		signature = firstValueInDefinition;
		parameterList = [arguments objectAtIndex:2];
		implementation = [STList listWithList:[arguments objectAtIndex:3]];
	}
	else
	{
		parameterList = firstValueInDefinition;
		implementation = [STList listWithList:[arguments objectAtIndex:2]];
		
		NSMutableString *signatureInProgress = [NSMutableString stringWithString:@"@"];
		for (NSUInteger index = 0; index < [parameterList count]; index++)
			[signatureInProgress appendString:@"@"];
		
		signature = signatureInProgress;
	}
	implementation.isQuoted = NO;
	
	STClosure *closure = [[[STClosure alloc] initWithPrototype:parameterList
											 forImplementation:implementation
												 withSignature:[NSMethodSignature signatureWithObjCTypes:[signature UTF8String]]
												 fromEvaluator:evaluator 
													   inScope:scope] autorelease];
	NSString *functionName = [[arguments objectAtIndex:0] string];
	[scope setObject:closure forKey:functionName];
	
	return closure;
});

STBuiltInFunctionDefine(SendMessage, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	id target = EvaluateExpression(evaluator, [arguments head], scope);
	return SendMessageWithTargetAndArguments(evaluator, target, [arguments tail], scope);
});

#pragma mark -

@implementation STEvaluator

#pragma mark Destruction

- (void)dealloc
{
	[mRootScope release];
	mRootScope = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if((self = [super init]))
	{
		mRootScope = [NSMutableDictionary new];
		
		//Built in Math Functions
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Add, self) forKey:@"+"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Subtract, self) forKey:@"-"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Multiply, self) forKey:@"*"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Divide, self) forKey:@"/"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Modulo, self) forKey:@"%"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Power, self) forKey:@"**"];
		
		//Built in Comparison Functions
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Equal, self) forKey:@"="];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(NotEqual, self) forKey:@"≠"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(LessThan, self) forKey:@"<"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(LessThanOrEqual, self) forKey:@"≤"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThan, self) forKey:@">"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThanOrEqual, self) forKey:@"≥"];
		
		//Core Built ins
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Set, self) forKey:@"set"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Lambda, self) forKey:@"lambda"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(Function, self) forKey:@"function"];
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(SendMessage, self) forKey:@"#"];
		
		//Bridging
		[mRootScope setObject:STBuiltInFunctionWithNameForEvaluator(BridgeFunction, self) forKey:@"bridge-function"];
		
		//Constants
		[mRootScope setObject:[NSNumber numberWithBool:YES] forKey:@"true"];
		[mRootScope setObject:[NSNumber numberWithBool:NO] forKey:@"false"];
		[mRootScope setObject:[NSNull null] forKey:@"null"];
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Root Scope

- (void)setValue:(id)value forKeyInRootScope:(NSString *)key
{
	@synchronized(self)
	{
		if(value)
			[mRootScope setObject:value forKey:key];
		else
			[mRootScope removeObjectForKey:key];
	}
}

- (id)valueForKeyInRootScope:(NSString *)key
{
	@synchronized(self)
	{
		return [mRootScope objectForKey:key];
	}
}

#pragma mark -

@synthesize rootScope = mRootScope;

#pragma mark -
#pragma mark Context Scope

- (NSMutableDictionary *)scopeWithEnclosingScope:(NSMutableDictionary *)enclosingScope
{
	NSMutableDictionary *scope = [NSMutableDictionary dictionaryWithCapacity:1];
	if(enclosingScope)
		[scope setObject:enclosingScope forKey:kSTEvaluatorEnclosingScopeKey];
	else
		[scope setObject:mRootScope forKey:kSTEvaluatorEnclosingScopeKey];
	
	return scope;
}

#pragma mark -
#pragma mark Variables

static NSMutableDictionary *LastScopeWithVariableNamed(NSMutableDictionary *currentScope, NSString *name)
{
	while (currentScope != nil)
	{
		if([[currentScope allKeys] containsObject:name])
			return currentScope;
		
		currentScope = [currentScope objectForKey:kSTEvaluatorEnclosingScopeKey];
	}
	
	return nil;
}

- (void)setObject:(id)object forVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope
{
	NSMutableDictionary *targetScope = LastScopeWithVariableNamed(scope, name);
	if(!targetScope)
		targetScope = scope;
	
	if(object)
		[targetScope setObject:object forKey:name];
	else
		[targetScope removeObjectForKey:name];
}

- (id)objectForVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope
{
	NSMutableDictionary *targetScope = LastScopeWithVariableNamed(scope, name);
	if(targetScope)
	{
		id value = [self valueForKeyInRootScope:name];
		if(value)
			return value;
	}
	
	Class class = NSClassFromString(name);
	NSAssert((class != nil), @"Could not find a value for the variable '%@'.", name);
	
	return class;
}

#pragma mark -
#pragma mark Parsing

- (NSArray *)parseString:(NSString *)string
{
	return STParseString(string, self);
}

#pragma mark -
#pragma mark Evaluation

static STList *EvaluateArgumentList(STEvaluator *self, STList *arguments, NSMutableDictionary *scope)
{
	STList *evaluatedArguments = [STList list];
	for (id expression in arguments)
	{
		id evaluateArgument = EvaluateExpression(self, expression, scope);
		[evaluatedArguments addObject:evaluateArgument];
	}
	
	return evaluatedArguments;
}

static id SendMessageWithTargetAndArguments(STEvaluator *self, id target, STList *arguments, NSMutableDictionary *scope)
{
	NSMutableString *selector = [NSMutableString string];
	NSMutableArray *evaluatedArguments = [NSMutableArray array];
	
	NSUInteger index = 0;
	for (id expression in arguments)
	{
		//If it's even, it's part of the selector
		if((index % 2) == 0)
			[selector appendString:[expression string]];
		else
			[evaluatedArguments addObject:EvaluateExpression(self, expression, scope)];
		
		index++;
	}
	
	return STMessageBridgeSend(target, NSSelectorFromString(selector), evaluatedArguments);
}

static id EvaluateList(STEvaluator *self, STList *list, NSMutableDictionary *scope)
{
	if([list count] == 0)
		return [NSNull null];
	
	if(list.isQuoted)
		return list;
	
	id target = EvaluateExpression(self, [list head], scope);
	
	if([target conformsToProtocol:@protocol(STFunction)])
	{
		NSObject < STFunction > *function = target;
		if([function evaluatesOwnArguments])
			return [function applyWithArguments:[list tail] inScope:self->mRootScope];
		
		STList *evaluatedArguments = EvaluateArgumentList(self, [list tail], scope);
		return [function applyWithArguments:evaluatedArguments inScope:self->mRootScope];
	}
	
	if([list count] == 1)
		return target;
	
	return SendMessageWithTargetAndArguments(self, target, [list tail], scope);
}

#pragma mark -

static id EvaluateExpression(STEvaluator *self, id expression, NSMutableDictionary *scope)
{
	if([expression isKindOfClass:[NSArray class]])
	{
		id lastResult = nil;
		for (id subexpression in expression)
			lastResult = EvaluateExpression(self, subexpression, scope);
		
		return lastResult;
	}
	else if([expression isKindOfClass:[STList class]])
	{
		return EvaluateList(self, expression, scope);
	}
	else if([expression isKindOfClass:[STSymbol class]])
	{
		return [self objectForVariableNamed:[expression string] inScope:scope];
	}
	
	return expression;
}

- (id)evaluateExpression:(id)expression inScope:(NSMutableDictionary *)scope
{
	if(!scope)
		scope = mRootScope;
	
	return EvaluateExpression(self, expression, scope);
}

#pragma mark -

- (id)parseAndEvaluateString:(NSString *)string
{
	return [self evaluateExpression:[self parseString:string] inScope:mRootScope];
}

@end
