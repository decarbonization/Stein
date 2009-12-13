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
#import "STMessageBridge.h"

#import "STBuiltInFunctions.h"

static id EvaluateExpression(STEvaluator *self, id expression);

#pragma mark -
#pragma mark Core Built Ins

STBuiltInFunctionDefine(Set, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *context) {
	NSCAssert(([arguments count] >= 2), 
			  @"Wrong number of arguments given to set, expected 2 got %ld.", [arguments count]);
	
	NSString *key = [[arguments objectAtIndex:0] string];
	id value = EvaluateExpression(evaluator, [arguments objectAtIndex:1]);
	[context setValue:value forKey:key];
	
	return value;
});

#pragma mark -

@implementation STEvaluator

#pragma mark Destruction

- (void)dealloc
{
	[mRootContext release];
	mRootContext = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if((self = [super init]))
	{
		mRootContext = [NSMutableDictionary new];
		
		//Built in Math Functions
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Add, self) forKey:@"+"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Subtract, self) forKey:@"-"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Multiply, self) forKey:@"*"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Divide, self) forKey:@"/"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Modulo, self) forKey:@"%"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Power, self) forKey:@"**"];
		
		//Built in Comparison Functions
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Equal, self) forKey:@"="];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(NotEqual, self) forKey:@"≠"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(LessThan, self) forKey:@"<"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(LessThanOrEqual, self) forKey:@"≤"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThan, self) forKey:@">"];
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(GreaterThanOrEqual, self) forKey:@"≥"];
		
		//Built in Variable Functions
		[mRootContext setObject:STBuiltInFunctionWithNameForEvaluator(Set, self) forKey:@"set"];
		
		//Constants
		[mRootContext setObject:[NSNumber numberWithBool:YES] forKey:@"true"];
		[mRootContext setObject:[NSNumber numberWithBool:NO] forKey:@"false"];
		[mRootContext setObject:[NSNull null] forKey:@"null"];
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Root Context

- (void)setValue:(id)value forKeyInRootContext:(NSString *)key
{
	@synchronized(self)
	{
		if(value)
			[mRootContext setObject:value forKey:key];
		else
			[mRootContext removeObjectForKey:key];
	}
}

- (id)valueForKeyInRootContext:(NSString *)key
{
	@synchronized(self)
	{
		return [mRootContext objectForKey:key];
	}
}

#pragma mark -

@synthesize rootContext = mRootContext;

#pragma mark -
#pragma mark Variables

- (void)setObject:(id)object forVariableNamed:(NSString *)name
{
	[self setValue:object forKeyInRootContext:name];
}

- (id)objectForVariableNamed:(NSString *)name
{
	id value = [self valueForKeyInRootContext:name];
	if(value)
		return value;
	
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

static STList *EvaluateArgumentList(STEvaluator *self, STList *arguments)
{
	STList *evaluatedArguments = [STList list];
	for (id expression in arguments)
	{
		id evaluateArgument = EvaluateExpression(self, expression);
		[evaluatedArguments addObject:evaluateArgument];
	}
	
	return evaluatedArguments;
}

static id SendMessageWithTargetAndArguments(STEvaluator *self, id target, STList *arguments)
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
			[evaluatedArguments addObject:EvaluateExpression(self, expression)];
		
		index++;
	}
	
	return STMessageBridgeSend(target, NSSelectorFromString(selector), evaluatedArguments);
}

static id EvaluateList(STEvaluator *self, STList *list)
{
	if([list count] == 0)
		return [NSNull null];
	
	if(list.isQuoted)
	{
		list.evaluator = self;
		return list;
	}
	
	id target = EvaluateExpression(self, [list head]);
	
	if([target conformsToProtocol:@protocol(STFunction)])
	{
		NSObject < STFunction > *function = target;
		if([function evaluatesOwnArguments])
			return [function applyWithArguments:[list tail] inContext:self->mRootContext];
		
		STList *evaluatedArguments = EvaluateArgumentList(self, [list tail]);
		return [function applyWithArguments:evaluatedArguments inContext:self->mRootContext];
	}
	
	if([list count] == 1)
		return target;
	
	return SendMessageWithTargetAndArguments(self, target, [list tail]);
}

#pragma mark -

static id EvaluateExpression(STEvaluator *self, id expression)
{
	if([expression isKindOfClass:[NSArray class]])
	{
		id lastResult = nil;
		for (id subexpression in expression)
			lastResult = EvaluateExpression(self, subexpression);
		
		return lastResult;
	}
	else if([expression isKindOfClass:[STList class]])
	{
		return EvaluateList(self, expression);
	}
	else if([expression isKindOfClass:[STSymbol class]])
	{
		return [self objectForVariableNamed:[expression string]];
	}
	
	return expression;
}

- (id)evaluateExpression:(id)expression
{
	return EvaluateExpression(self, expression);
}

#pragma mark -

- (id)parseAndEvaluateString:(NSString *)string
{
	return [self evaluateExpression:[self parseString:string]];
}

@end
