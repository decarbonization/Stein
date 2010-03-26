//
//  NSObject+Stein.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "NSObject+Stein.h"
#import <objc/objc-runtime.h>
#import "STObjectBridge.h"
#import "STTypeBridge.h"
#import "STStructClasses.h"

#import "STFunction.h"
#import "STList.h"
#import "STClosure.h"
#import "STSymbol.h"
#import "STEvaluator.h"

static NSString *const kNSObjectAdditionalIvarsTableKey = @"NSObject_additionalIvarsTable";

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
#pragma mark If Statements

- (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause
{
	if([self isTrue])
	{
		return STFunctionApply(thenClause, [STList list]);
	}
	
	return STFunctionApply(elseClause, [STList list]);
}

+ (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause
{
	if([self isTrue])
	{
		return STFunctionApply(thenClause, [STList list]);
	}
	
	return STFunctionApply(elseClause, [STList list]);
}

#pragma mark -

- (id)ifTrue:(id < STFunction >)thenClause
{
	return [self ifTrue:thenClause ifFalse:nil];
}

+ (id)ifTrue:(id < STFunction >)thenClause
{
	return [self ifTrue:thenClause ifFalse:nil];
}

#pragma mark -

- (id)ifFalse:(id < STFunction >)thenClause
{
	return [self ifTrue:nil ifFalse:thenClause];
}

+ (id)ifFalse:(id < STFunction >)thenClause
{
	return [self ifTrue:nil ifFalse:thenClause];
}

#pragma mark -
#pragma mark Matching

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

+ (id)match:(STClosure *)matchers
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

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"`%@`", [[self description] stringByReplacingOccurrencesOfString:@"`" 
																							 withString:@"\\`"]];
}

+ (NSString *)prettyDescription
{
	return NSStringFromClass(self);
}

#pragma mark -

- (NSString *)prettyPrint
{
	NSString *prettyDescription = [self prettyDescription];
	
	puts([prettyDescription UTF8String]);
	
	return prettyDescription;
}

+ (NSString *)prettyPrint
{
	NSString *prettyDescription = [self prettyDescription];
	
	puts([prettyDescription UTF8String]);
	
	return prettyDescription;
}

#pragma mark -

- (NSString *)print
{
	NSString *description = [self description];
	
	puts([description UTF8String]);
	
	return description;
}

+ (NSString *)print
{
	NSString *description = [self description];
	
	puts([description UTF8String]);
	
	return description;
}

#pragma mark -
#pragma mark Ivars

- (void)setValue:(id)value forIvarNamed:(NSString *)name
{
	Ivar ivar = class_getInstanceVariable([self class], [name UTF8String]);
	if(!ivar)
	{
		NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, kNSObjectAdditionalIvarsTableKey);
		if(!ivarTable)
		{
			ivarTable = [NSMutableDictionary dictionary];
			objc_setAssociatedObject(self, kNSObjectAdditionalIvarsTableKey, ivarTable, OBJC_ASSOCIATION_RETAIN);
		}
		
		if(value)
			[ivarTable setObject:value forKey:name];
		else
			[ivarTable removeObjectForKey:value];
		
		return;
	}
	
	const char *ivarTypeEncoding = ivar_getTypeEncoding(ivar);
	Byte buffer[STTypeBridgeGetSizeOfObjCType(ivarTypeEncoding)];
	STTypeBridgeConvertObjectIntoType(value, ivarTypeEncoding, (void **)&buffer);
	object_setIvar(self, ivar, (void *)buffer);
}

- (id)valueForIvarNamed:(NSString *)name
{
	Ivar ivar = class_getInstanceVariable([self class], [name UTF8String]);
	if(!ivar)
	{
		NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, kNSObjectAdditionalIvarsTableKey);
		return [ivarTable objectForKey:name];
	}
	
	void *location = object_getIvar(self, ivar);
	return STTypeBridgeConvertValueOfTypeIntoObject(&location, ivar_getTypeEncoding(ivar));
}

#pragma mark -

+ (void)setValue:(id)value forIvarNamed:(NSString *)name
{
	NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, kNSObjectAdditionalIvarsTableKey);
	if(!ivarTable)
	{
		ivarTable = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, kNSObjectAdditionalIvarsTableKey, ivarTable, OBJC_ASSOCIATION_RETAIN);
	}
	
	if(value)
		[ivarTable setObject:value forKey:name];
	else
		[ivarTable removeObjectForKey:value];
}

+ (id)valueForIvarNamed:(NSString *)name
{
	NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, kNSObjectAdditionalIvarsTableKey);
	return [ivarTable objectForKey:name];
}

#pragma mark -
#pragma mark Extension

+ (Class)extend:(STClosure *)extensions inEvaluator:(STEvaluator *)evaluator
{
	STExtendClass(self, extensions.implementation, evaluator);
	return self;
}

#pragma mark -
#pragma mark High-Level Forwarding

+ (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator
{
	return NO;
}

+ (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark -

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator
{
	return NO;
}

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end

#pragma mark -

@implementation NSNumber (Stein)

+ (void)load
{
	static BOOL hasAddedPrettyMethods = NO;
	if(!hasAddedPrettyMethods)
	{
		//Add support for the @selector(to) method.
#if __LP64__
		class_addMethod(self, 
						@selector(to), 
						[self instanceMethodForSelector:@selector(rangeWithLength:)], 
						"@@:L");
#else
		class_addMethod(self, 
						@selector(to), 
						[self instanceMethodForSelector:@selector(rangeWithLength:)], 
						"@@:I");
#endif
		
		hasAddedPrettyMethods = YES;
	}
}

#pragma mark -

- (BOOL)isTrue
{
	return [self boolValue];
}

- (NSString *)prettyDescription
{
	return [self description];
}

- (STRange *)rangeWithLength:(NSUInteger)length
{
	return [[STRange alloc] initWithLocation:[self unsignedIntegerValue] length:length];
}

#pragma mark -
#pragma mark Infix Notation Support

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator
{
	NSString *selectorString = NSStringFromSelector(selector);
	for (NSUInteger index = 0, length = [selectorString length]; index < length; index++)
	{
		unichar character = [selectorString characterAtIndex:index];
		if(character != '+' && 
		   character != '-' && 
		   character != '*' && 
		   character != '/' && 
		   character != '^')
		{
			return NO;
		}
	}
	
	return YES;
}

typedef struct Operation {
	int originalPosition;
	char operatorName;
} Operation;

ST_INLINE int PrecedenceOfOperatorNamed(char operatorName)
{
	switch (operatorName)
	{
		case '+':
		case '-':
			return 1;
			
		case '*':
		case '/':
			return 2;
			
		case '^':
			return 3;
			
		default:
			break;
	}
	
	return 0;
}

static int OperationPrecedenceComparator(Operation *left, Operation *right)
{
	int leftPrecedence = PrecedenceOfOperatorNamed(left->operatorName);
	int rightPrecedence = PrecedenceOfOperatorNamed(right->operatorName);
	
	if(leftPrecedence > rightPrecedence)
		return -1;
	else if(leftPrecedence < rightPrecedence)
		return 1;
	
	return 0;
}

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator
{
	const char *operators = sel_getName(selector);
	
	int numberOfOperations = strlen(operators);
	Operation operations[numberOfOperations];
	for (int operationOffset = 0; operationOffset < numberOfOperations; operationOffset++)
	{
		operations[operationOffset] = (Operation){
			.originalPosition = operationOffset,
			.operatorName = operators[operationOffset]
		};
	}
	
	qsort(operations, numberOfOperations, sizeof(Operation), (void *)&OperationPrecedenceComparator);
	
	NSMutableArray *pool = [NSMutableArray arrayWithArray:arguments];
	[pool insertObject:self atIndex:0];
	for (int index = 0; index < numberOfOperations; index++)
	{
		Operation operation = operations[index];
		double leftOperand = [[pool objectAtIndex:operation.originalPosition] doubleValue];
		double rightOperand = [[pool objectAtIndex:operation.originalPosition + 1] doubleValue];
		double result = 0;
		switch (operation.operatorName)
		{
			case '+':
				result = leftOperand + rightOperand;
				break;
				
			case '-':
				result = leftOperand - rightOperand;
				break;
				
			case '*':
				result = leftOperand * rightOperand;
				break;
				
			case '/':
				result = leftOperand / rightOperand;
				break;
				
			case '^':
				result = pow(leftOperand, rightOperand);
				break;
				
			default:
				break;
		}
		
		NSNumber *resultNumber = [NSNumber numberWithDouble:result];
		[pool replaceObjectAtIndex:operation.originalPosition withObject:resultNumber];
		[pool replaceObjectAtIndex:operation.originalPosition + 1 withObject:resultNumber];
	}
	
	return [pool objectAtIndex:operations[numberOfOperations - 1].originalPosition];
}

@end

#pragma mark -

@implementation NSString (Stein)

- (NSString *)string
{
	return self;
}

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"\"%@\"", [self stringByReplacingOccurrencesOfString:@"\"" 
																				 withString:@"\\\""]];
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

- (NSString *)prettyDescription
{
	return @"null";
}

@end

#pragma mark -

@implementation NSArray (Stein)

#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		@try
		{
			STFunctionApply(function, [STList listWithObject:object]);
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableArray *mappedObjects = [NSMutableArray array];
	
	for (id object in self)
	{
		@try
		{
			id mappedObject = STFunctionApply(function, [STList listWithObject:object]);
			if(!mappedObject)
				continue;
			
			[mappedObjects addObject:mappedObject];
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return mappedObjects;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableArray *filteredObjects = [NSMutableArray array];
	
	for (id object in self)
	{
		@try
		{
			if([STFunctionApply(function, [STList listWithObject:object]) isTrue])
				[filteredObjects addObject:object];
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return filteredObjects;
}

#pragma mark -
#pragma mark Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"{\n"];
	
	for (id object in self)
	{
		[description appendFormat:@"\t%@\n", [object prettyDescription]];
	}
	
	[description appendString:@"}"];
	
	return description;
}

#pragma mark -
#pragma mark Mass Messaging Support

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator
{
	return [[self objectAtIndex:0] respondsToSelector:selector];
}

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator
{
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[self count]];
	for (id object in self)
		[results addObject:STObjectBridgeSend(object, selector, [arguments copy], evaluator)];
	
	return results;
}

@end

#pragma mark -

@implementation NSSet (Stein)

#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		@try
		{
			STFunctionApply(function, [STList listWithObject:object]);
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableSet *mappedObjects = [NSMutableSet set];
	
	for (id object in self)
	{
		@try
		{
			id mappedObject = STFunctionApply(function, [STList listWithObject:object]);
			if(!mappedObject)
				continue;
			
			[mappedObjects addObject:mappedObject];
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return mappedObjects;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableSet *filteredObjects = [NSMutableSet set];
	
	for (id object in self)
	{
		@try
		{
			if([STFunctionApply(function, [STList listWithObject:object]) isTrue])
				[filteredObjects addObject:object];
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return filteredObjects;
}

#pragma mark -
#pragma mark Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"{\n"];
	
	for (id object in self)
	{
		[description appendFormat:@"\t%@\n", [object prettyDescription]];
	}
	
	[description appendString:@"}"];
	
	return description;
}

#pragma mark -
#pragma mark Mass Messaging Support

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator
{
	return [[self anyObject] respondsToSelector:selector];
}

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator
{
	NSMutableArray *results = [NSMutableSet setWithCapacity:[self count]];
	for (id object in self)
		[results addObject:STObjectBridgeSend(object, selector, [arguments copy], evaluator)];
	
	return results;
}

@end

#pragma mark -

@implementation NSDictionary (Stein)

#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		@try
		{
			STFunctionApply(function, [STList listWithArray:[NSArray arrayWithObjects:key, value, nil]]);
		}
		@catch (STBreakException *e)
		{
			*stop = YES;
			return;
		}
		@catch (STContinueException *e)
		{
			return;
		}
	}];
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		@try
		{
			id mappedValue = STFunctionApply(function, [STList listWithArray:[NSArray arrayWithObjects:key, value, nil]]);
			if([mappedValue isTrue])
				[result setObject:mappedValue forKey:key];
		}
		@catch (STBreakException *e)
		{
			*stop = YES;
			return;
		}
		@catch (STContinueException *e)
		{
			return;
		}
	}];
	
	return result;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		@try
		{
			if([STFunctionApply(function, [STList listWithArray:[NSArray arrayWithObjects:key, value, nil]]) isTrue])
				[result setObject:value forKey:key];
		}
		@catch (STBreakException *e)
		{
			*stop = YES;
			return;
		}
		@catch (STContinueException *e)
		{
			return;
		}
	}];
	
	return result;
}

#pragma mark -
#pragma mark Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"{\n"];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		[description appendFormat:@"\t%@ => %@\n", [key prettyDescription], [value prettyDescription]];
	}];
	
	[description appendString:@"}"];
	
	return description;
}

@end
