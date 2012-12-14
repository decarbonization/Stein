//
//  NSObject+SteinTools.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "NSObject+SteinTools.h"
#import "NSObject+SteinInternalSupport.h"
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

#pragma mark - Extension

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

#pragma mark - Operators

- (id)operatorAdd:(id)rightOperand
{
	return [NSNumber numberWithDouble:[self doubleValue] + [rightOperand doubleValue]];
}

- (id)operatorSubtract:(id)rightOperand
{
	return [NSNumber numberWithDouble:[self doubleValue] - [rightOperand doubleValue]];
}

- (id)operatorMultiply:(id)rightOperand
{
	return [NSNumber numberWithDouble:[self doubleValue] * [rightOperand doubleValue]];
}

- (id)operatorDivide:(id)rightOperand
{
	return [NSNumber numberWithDouble:[self doubleValue] / [rightOperand doubleValue]];
}

- (id)operatorPower:(id)rightOperand
{
	return [NSNumber numberWithDouble:pow([self doubleValue], [rightOperand doubleValue])];
}

@end

@implementation NSDecimalNumber (SteinTools)

#pragma mark Operators

- (NSDecimalNumber *)operatorAdd:(NSDecimalNumber *)rightOperand
{
	return [self decimalNumberByAdding:rightOperand];
}

- (NSDecimalNumber *)operatorSubtract:(NSDecimalNumber *)rightOperand
{
	return [self decimalNumberBySubtracting:rightOperand];
}

- (NSDecimalNumber *)operatorMultiply:(NSDecimalNumber *)rightOperand
{
	return [self decimalNumberByMultiplyingBy:rightOperand];
}

- (NSDecimalNumber *)operatorDivide:(NSDecimalNumber *)rightOperand
{
	return [self decimalNumberByDividingBy:rightOperand];
}

- (NSDecimalNumber *)operatorPower:(NSDecimalNumber *)rightOperand
{
	return [self decimalNumberByRaisingToPower:[rightOperand unsignedIntegerValue]];
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

#pragma mark - Operators

- (NSString *)operatorAdd:(NSString *)rightOperand
{
	return [self stringByAppendingString:[rightOperand string]];
}

- (NSString *)operatorSubtract:(NSString *)rightOperand
{
	return [self stringByReplacingOccurrencesOfString:rightOperand withString:@""];
}

- (NSString *)operatorMultiply:(id)rightOperand
{
	NSMutableString *result = [NSMutableString string];
	for (NSInteger time = 0, total = [rightOperand integerValue]; time < total; time++)
	{
		[result appendString:self];
	}
	
	return [result copy];
}

#pragma mark - Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (NSUInteger index = 0, length = [self length]; index < length; index++)
	{
		@try
		{
			NSNumber *character = [NSNumber numberWithChar:[self characterAtIndex:index]];
			STFunctionApply(function, [[STList alloc] initWithObjects:character, nil]);
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
	NSMutableString *string = [NSMutableString string];
	for (NSUInteger index = 0, length = [self length]; index < length; index++)
	{
		@try
		{
			NSNumber *character = [NSNumber numberWithChar:[self characterAtIndex:index]];
			id result = STFunctionApply(function, [[STList alloc] initWithObjects:character, nil]);
			if([result isKindOfClass:[NSNumber class]])
			{
				[string appendFormat:@"%C", [result charValue]];
			}
			else
			{
				[string appendString:[result description]];
			}
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
	
	return [string copy];
}

- (id)filter:(id < STFunction >)function
{
	NSMutableString *string = [NSMutableString string];
	for (NSUInteger index = 0, length = [self length]; index < length; index++)
	{
		@try
		{
			NSNumber *character = [NSNumber numberWithChar:[self characterAtIndex:index]];
			if(STIsTrue(STFunctionApply(function, [[STList alloc] initWithObjects:character, nil])))
			{
				[string appendFormat:@"%C", [character charValue]];
			}
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
	
	return [string copy];
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

#pragma mark Operators

- (NSArray *)operatorAdd:(NSArray *)rightOperand
{
	return [self arrayByAddingObjectsFromArray:rightOperand];
}

- (NSArray *)operatorSubtract:(NSArray *)rightOperand
{
	NSMutableArray *result = [self mutableCopy];
	[result removeObjectsInArray:rightOperand];
	return [result copy];
}

#pragma mark - Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		@try
		{
			STFunctionApply(function, [[STList alloc] initWithObject:object]);
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
			id mappedObject = STFunctionApply(function, [[STList alloc] initWithObject:object]);
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
	
	return [mappedObjects copy];
}

- (id)filter:(id < STFunction >)function
{
	NSMutableArray *filteredObjects = [NSMutableArray array];
	
	for (id object in self)
	{
		@try
		{
			if(STIsTrue(STFunctionApply(function, [[STList alloc] initWithObject:object])))
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
	
	return [filteredObjects copy];
}

#pragma mark - Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"(array"];
	
	for (id object in self)
	{
		[description appendFormat:@" %@", [object prettyDescription]];
	}
	
	[description appendString:@")"];
	
	return description;
}

#pragma mark - Array Programming Support

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

#pragma mark Operators

- (NSSet *)operatorAdd:(NSSet *)rightOperand
{
	return [self setByAddingObjectsFromSet:rightOperand];
}

- (NSSet *)operatorSubtract:(NSSet *)rightOperand
{
	NSMutableSet *result = [self mutableCopy];
	[result minusSet:rightOperand];
	return [result copy];
}

#pragma mark - Enumerable

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		@try
		{
			STFunctionApply(function, [[STList alloc] initWithObject:object]);
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
			id mappedObject = STFunctionApply(function, [[STList alloc] initWithObject:object]);
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
	
	return [mappedObjects copy];
}

- (id)filter:(id < STFunction >)function
{
	NSMutableSet *filteredObjects = [NSMutableSet set];
	
	for (id object in self)
	{
		@try
		{
			if(STIsTrue(STFunctionApply(function, [[STList alloc] initWithObject:object])))
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
	
	return [filteredObjects copy];
}

#pragma mark - Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"(set"];
	
	for (id object in self)
	{
		[description appendFormat:@" %@", [object prettyDescription]];
	}
	
	[description appendString:@")"];
	
	return description;
}

@end

#pragma mark -

@implementation NSIndexSet (SteinTools)

#pragma mark Implementing <STEnumerable>

- (id)foreach:(id <STFunction>)function
{
	[self enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		@try
		{
			NSNumber *number = [NSNumber numberWithUnsignedInteger:index];
			STFunctionApply(function, [[STList alloc] initWithObject:number]);
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

- (id)map:(id <STFunction>)function
{
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	[self enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		@try
		{
			NSNumber *number = [NSNumber numberWithUnsignedInteger:index];
			[indexSet addIndex:[STFunctionApply(function, [[STList alloc] initWithObject:number]) unsignedIntegerValue]];
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
	
	return [indexSet copy];
}

- (id)filter:(id <STFunction>)function
{
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	[self enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		@try
		{
			NSNumber *number = [NSNumber numberWithUnsignedInteger:index];
			if(STIsTrue(STFunctionApply(function, [[STList alloc] initWithObject:number])))
				[indexSet addIndex:index];
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
	
	return [indexSet copy];
}

#pragma mark - Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"(index-set"];
	
	[self enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		[description appendFormat:@" %ld", index];
	}];
	
	[description appendString:@")"];
	return description;
}

@end

#pragma mark -

@implementation NSDictionary (SteinTools)

#pragma mark Operators

- (NSDictionary *)operatorAdd:(NSDictionary *)rightOperand
{
	NSMutableDictionary *result = [self mutableCopy];
	[result setValuesForKeysWithDictionary:rightOperand];
	return [result copy];
}

- (NSDictionary *)operatorSubtract:(id)rightOperand
{
	NSMutableDictionary *result = [self mutableCopy];
	if([rightOperand isKindOfClass:[NSDictionary class]])
		[result removeObjectsForKeys:[rightOperand allKeys]];
	else if([rightOperand isKindOfClass:[NSArray class]])
		[result removeObjectsForKeys:rightOperand];
	else
		[result removeObjectsForKeys:[rightOperand allObjects]];
	
	return [result copy];
}

#pragma mark - Enumerable

- (id)foreach:(id < STFunction >)function
{
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		@try
		{
			STFunctionApply(function, [[STList alloc] initWithArray:[NSArray arrayWithObjects:key, value, nil]]);
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
			id mappedValue = STFunctionApply(function, [[STList alloc] initWithArray:[NSArray arrayWithObjects:key, value, nil]]);
			if(STIsTrue(mappedValue))
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
	
	return [result copy];
}

- (id)filter:(id < STFunction >)function
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		@try
		{
			if(STIsTrue(STFunctionApply(function, [[STList alloc] initWithArray:[NSArray arrayWithObjects:key, value, nil]])))
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
	
	return [result copy];
}

#pragma mark - Pretty Printing

- (NSString *)prettyDescription
{
	NSMutableString *description = [NSMutableString stringWithString:@"(dictionary"];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		[description appendFormat:@" %@ %@", [key prettyDescription], [value prettyDescription]];
	}];
	
	[description appendString:@")"];
	
	return description;
}

@end
