//
//  NSObject+SteinTools.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "NSObject+SteinTools.h"
#import <objc/objc-runtime.h>
#import "STObjectBridge.h"
#import "STTypeBridge.h"

#import "STFunction.h"
#import "STList.h"
#import "STClosure.h"
#import "STSymbol.h"

@implementation NSObject (SteinTools)

#pragma mark Printing

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"`%@`", [[self description] stringByReplacingOccurrencesOfString:@"`" 
																							 withString:@"\\`"]];
}

+ (NSString *)prettyDescription
{
	return [self className];
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
#pragma mark Extension

+ (Class)extend:(STClosure *)extensions
{
	STExtendClass(self, extensions.implementation);
	return self;
}

@end

#pragma mark -

@implementation NSNumber (SteinTools)

- (NSString *)prettyDescription
{
	return [self description];
}

#pragma mark -
#pragma mark Infix Notation Support

static BOOL IsCharacterSequenceOperator(unichar left, unichar right)
{
	return (left == '+' || left == '-' || 
			left == '*' || left == '/' || 
			left == '%' || left == '^' || 
			left == '<' || (left == '<' && right == '=') || 
			left == '>' || (left == '>' && right == '=') || 
			left == '|' || left == '&');
}

static BOOL IsSelectorComposedOfOperators(SEL selector)
{
	NSString *selectorString = NSStringFromSelector(selector);
	for (NSUInteger index = 0, length = [selectorString length]; index < length; index++)
	{
		unichar leftCharacter = [selectorString characterAtIndex:index];
		unichar rightCharacter = (index + 1 < length)? [selectorString characterAtIndex:index + 1] : 0;
		if(!IsCharacterSequenceOperator(leftCharacter, rightCharacter))
			return NO;
		
		if(rightCharacter != 0)
			index++;
	}
	
	return YES;
}

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector
{
	return IsSelectorComposedOfOperators(selector);
}

#pragma mark -

typedef struct Operation {
	int originalPosition;
	char operatorName[2];
} Operation;

static BOOL streq(const char *left, const char *right)
{
	if(strlen(left) != strlen(right))
		return NO;
	
	for (int index = 0, length = strlen(left); index < length; index++)
	{
		if(left[index] != right[index])
			return NO;
	}
	
	return YES;
}

ST_INLINE int PrecedenceOfOperatorNamed(char operatorName[3])
{
	if(streq(operatorName, "|"))
	{
		return 1;
	}
	if(streq(operatorName, "&"))
	{
		return 2;
	}
	if(streq(operatorName, "+") || streq(operatorName, "-"))
	{
		return 3;
	}
	else if(streq(operatorName, "*") || streq(operatorName, "/") || streq(operatorName, "%"))
	{
		return 4;
	}
	else if(streq(operatorName, "^"))
	{
		return 5;
	}
	
	return 0;
}

static int NumberOfOperators(const char *operatorString)
{
	return strlen(operatorString);
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

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope
{
	const char *operators = sel_getName(selector);
	
	int numberOfOperations = NumberOfOperators(operators);
	Operation operations[numberOfOperations];
	for (int operationOffset = 0, operatorsLength = strlen(operators); operationOffset < operatorsLength; operationOffset++)
	{
		operations[operationOffset].originalPosition = operationOffset;
		
		operations[operationOffset].operatorName[0] = operators[operationOffset];
		operations[operationOffset].operatorName[1] = '\0';
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
		
		if(streq(operation.operatorName, "+"))
		{
			result = leftOperand + rightOperand;
		}
		else if(streq(operation.operatorName, "-"))
		{
			result = leftOperand - rightOperand;
		}
		else if(streq(operation.operatorName, "*"))
		{
			result = leftOperand * rightOperand;
		}
		else if(streq(operation.operatorName, "/"))
		{
			result = leftOperand / rightOperand;
		}
		else if(streq(operation.operatorName, "%"))
		{
			result = (long)(leftOperand) % (long)(rightOperand);
		}
		else if(streq(operation.operatorName, "^"))
		{
			result = pow(leftOperand, rightOperand);
		}
		
		NSNumber *resultNumber = [NSNumber numberWithDouble:result];
		[pool replaceObjectAtIndex:operation.originalPosition withObject:resultNumber];
		[pool replaceObjectAtIndex:operation.originalPosition + 1 withObject:resultNumber];
	}
	
	return [pool objectAtIndex:operations[numberOfOperations - 1].originalPosition];
}

@end

#pragma mark -

@implementation NSString (SteinTools)

- (NSString *)string
{
	return self;
}

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"\"%@\"", [self stringByReplacingOccurrencesOfString:@"\"" 
																				 withString:@"\\\""]];
}

#pragma mark -
#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (NSUInteger index = 0, length = [self length]; index < length; index++)
	{
		NSNumber *character = [NSNumber numberWithChar:[self characterAtIndex:index]];
		STFunctionApply(function, [STList listWithObjects:character, nil]);
	}
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableString *string = [NSMutableString string];
	for (NSUInteger index = 0, length = [self length]; index < length; index++)
	{
		NSNumber *character = [NSNumber numberWithChar:[self characterAtIndex:index]];
		id result = STFunctionApply(function, [STList listWithObjects:character, nil]);
		if([result isKindOfClass:[NSNumber class]])
		{
			[string appendFormat:@"%C", [result charValue]];
		}
		else
		{
			[string appendString:[result description]];
		}
	}
	
	return string;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableString *string = [NSMutableString string];
	for (NSUInteger index = 0, length = [self length]; index < length; index++)
	{
		NSNumber *character = [NSNumber numberWithChar:[self characterAtIndex:index]];
		if(STIsTrue(STFunctionApply(function, [STList listWithObjects:character, nil])))
		{
			[string appendFormat:@"%C", [character charValue]];
		}
	}
	
	return string;
}

@end

#pragma mark -

@implementation NSNull (SteinTools)

- (NSString *)prettyDescription
{
	return @"null";
}

@end

#pragma mark -

@implementation NSArray (SteinTools)

#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		STFunctionApply(function, [STList listWithObject:object]);
	}
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableArray *mappedObjects = [NSMutableArray array];
	
	for (id object in self)
	{
		id mappedObject = STFunctionApply(function, [STList listWithObject:object]);
		if(!mappedObject)
			continue;
		
		[mappedObjects addObject:mappedObject];
	}
	
	return mappedObjects;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableArray *filteredObjects = [NSMutableArray array];
	
	for (id object in self)
	{
		if(STIsTrue(STFunctionApply(function, [STList listWithObject:object])))
			[filteredObjects addObject:object];
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
#pragma mark Array Programming Support

- (NSArray *)where:(NSArray *)booleans
{
	NSParameterAssert(booleans);
	NSAssert(([self count] <= [booleans count]), 
			 @"Wrong number of values given to where, expected at least %ld got %ld", [self count], [booleans count]);
	
	NSMutableArray *result = [NSMutableArray array];
	[booleans enumerateObjectsUsingBlock:^(id boolean, NSUInteger index, BOOL *stop) {
		if(STIsTrue(boolean))
			[result addObject:[self objectAtIndex:index]];
	}];
	
	return result;
}

#pragma mark -

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector
{
	id < NSObject, STMethodMissing > firstObject = [self objectAtIndex:0];
	return [firstObject respondsToSelector:selector];
}

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope
{
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[self count]];
	for (id object in self)
		[results addObject:STObjectBridgeSend(object, selector, [arguments copy], scope)];
	
	return results;
}

@end

#pragma mark -

@implementation NSSet (SteinTools)

#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		STFunctionApply(function, [STList listWithObject:object]);
	}
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableSet *mappedObjects = [NSMutableSet set];
	
	for (id object in self)
	{
		id mappedObject = STFunctionApply(function, [STList listWithObject:object]);
		if(!mappedObject)
			continue;
		
		[mappedObjects addObject:mappedObject];
	}
	
	return mappedObjects;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableSet *filteredObjects = [NSMutableSet set];
	
	for (id object in self)
	{
		if(STIsTrue(STFunctionApply(function, [STList listWithObject:object])))
			[filteredObjects addObject:object];
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

@end

#pragma mark -

@implementation NSDictionary (SteinTools)

#pragma mark Enumerable

- (id)foreach:(id < STFunction >)function
{
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		STFunctionApply(function, [STList listWithArray:[NSArray arrayWithObjects:key, value, nil]]);
	}];
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		id mappedValue = STFunctionApply(function, [STList listWithArray:[NSArray arrayWithObjects:key, value, nil]]);
		if(STIsTrue(mappedValue))
			[result setObject:mappedValue forKey:key];
	}];
	
	return result;
}

- (id)filter:(id < STFunction >)function
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		if(STIsTrue(STFunctionApply(function, [STList listWithArray:[NSArray arrayWithObjects:key, value, nil]])))
			[result setObject:value forKey:key];
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
