//
//  NSObject+SteinInternalSupport.m
//  stein
//
//  Created by Kevin MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "NSObject+SteinInternalSupport.h"

#import "STInterpreter.h"
#import "STList.h"

#import <objc/runtime.h>
#import "STTypeBridge.h"

static NSString *const kNSObjectAdditionalIvarsTableKey = @"NSObject_additionalIvarsTable";

@implementation NSObject (SteinInternalSupport)

#pragma mark Overrides

+ (void)load
{
	//Overrides for <STMethodMissing>
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(respondsToSelector:)), 
								   class_getInstanceMethod(self, @selector(stein_respondsToSelector:)));
	
	method_exchangeImplementations(class_getClassMethod(self, @selector(respondsToSelector:)), 
								   class_getClassMethod(self, @selector(stein_respondsToSelector:)));
	
	
	//Overrides for Ivar
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(valueForUndefinedKey:)), 
								   class_getInstanceMethod(self, @selector(stein_valueForUndefinedKey:)));
	
	method_exchangeImplementations(class_getClassMethod(self, @selector(setValue:forUndefinedKey:)), 
								   class_getClassMethod(self, @selector(stein_setValue:forUndefinedKey:)));
	
	
	//Overrides for unique class names
	method_exchangeImplementations(class_getClassMethod(self, @selector(description)), 
								   class_getClassMethod(self, @selector(stein_description)));
	
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(description)), 
								   class_getInstanceMethod(self, @selector(stein_description)));
}

#pragma mark - • Overrides for <STMethodMissing>

+ (BOOL)stein_respondsToSelector:(SEL)selector
{
	return [self stein_respondsToSelector:selector] || [self canHandleMissingMethodWithSelector:selector];
}

- (BOOL)stein_respondsToSelector:(SEL)selector
{
	return [self stein_respondsToSelector:selector] || [self canHandleMissingMethodWithSelector:selector];
}

#pragma mark - • Overrides for Unique Class Names

+ (NSString *)className
{
	return [self valueForIvarNamed:kSTClassNameVariableName] ?: NSStringFromClass([self class]);
}

- (NSString *)className
{
	return [[self class] className];
}

+ (NSString *)stein_description
{
	return [self className];
}

- (NSString *)stein_description
{
	return [NSString stringWithFormat:@"<%@:%p>", [self className], self];
}

#pragma mark - • Overrides for Ivar

- (id)stein_valueForUndefinedKey:(NSString *)key
{
	return [self valueForIvarNamed:key] ?: [self stein_valueForUndefinedKey:key];
}

- (void)stein_setValue:(id)value forUndefinedKey:(NSString *)key
{
	if([self valueForIvarNamed:key] != nil)
		[self stein_setValue:value forUndefinedKey:key];
	else
		[self setValue:value forIvarNamed:key];
}

#pragma mark - Ivars

- (void)setValue:(id)value forIvarNamed:(NSString *)name
{
	Ivar ivar = class_getInstanceVariable([self class], [name UTF8String]);
	if(!ivar)
	{
		NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, (__bridge const void *)(kNSObjectAdditionalIvarsTableKey));
		if(!ivarTable)
		{
			ivarTable = [NSMutableDictionary dictionary];
			objc_setAssociatedObject(self, (__bridge const void *)(kNSObjectAdditionalIvarsTableKey), ivarTable, OBJC_ASSOCIATION_RETAIN);
		}
		
		if(value)
			[ivarTable setObject:value forKey:name];
		else
			[ivarTable removeObjectForKey:value];
		
		return;
	}
	
	const char *ivarTypeEncoding = ivar_getTypeEncoding(ivar);
    NSUInteger ivarSize = 0;
    NSGetSizeAndAlignment(ivarTypeEncoding, &ivarSize, NULL);
	Byte buffer[ivarSize];
	STTypeBridgeConvertObjectIntoType(value, ivarTypeEncoding, (void **)&buffer);
	object_setIvar(self, ivar, (__bridge id)((void *)buffer));
}

- (id)valueForIvarNamed:(NSString *)name
{
	Ivar ivar = class_getInstanceVariable([self class], [name UTF8String]);
	if(!ivar)
	{
		NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, (__bridge const void *)(kNSObjectAdditionalIvarsTableKey));
		return [ivarTable objectForKey:name];
	}
	
	void *location = (__bridge void *)(object_getIvar(self, ivar));
	return STTypeBridgeConvertValueOfTypeIntoObject(&location, ivar_getTypeEncoding(ivar));
}

#pragma mark -

+ (void)setValue:(id)value forIvarNamed:(NSString *)name
{
	NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, (__bridge const void *)(kNSObjectAdditionalIvarsTableKey));
	if(!ivarTable)
	{
		ivarTable = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, (__bridge const void *)(kNSObjectAdditionalIvarsTableKey), ivarTable, OBJC_ASSOCIATION_RETAIN);
	}
	
	if(value)
		[ivarTable setObject:value forKey:name];
	else
		[ivarTable removeObjectForKey:value];
}

+ (id)valueForIvarNamed:(NSString *)name
{
	NSMutableDictionary *ivarTable = objc_getAssociatedObject(self, (__bridge const void *)(kNSObjectAdditionalIvarsTableKey));
	return [ivarTable objectForKey:name];
}

#pragma mark - Implementing <STMethodMissing>

+ (BOOL)canHandleMissingMethodWithSelector:(SEL)selector
{
	return NO;
}

+ (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope
{
	NSLog(@"[%s %s] called without concrete implementation. Did you forget to override it in your subclass?", class_getName([self class]), sel_getName(selector));
	return STNull;
}

#pragma mark - -
#pragma mark Infix Notation Support

static BOOL IsCharacterSequenceOperator(unichar left, unichar right)
{
	return (left == '+' || left == '-' || left == '*' || left == '/' || left == '^');
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
	else if(streq(operatorName, "*") || streq(operatorName, "/"))
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
		id leftOperand = [pool objectAtIndex:operation.originalPosition];
		id rightOperand = [pool objectAtIndex:operation.originalPosition + 1];
		id result = 0;
		
		if(streq(operation.operatorName, "+"))
		{
			result = [leftOperand operatorAdd:rightOperand];
		}
		else if(streq(operation.operatorName, "-"))
		{
			result = [leftOperand operatorSubtract:rightOperand];
		}
		else if(streq(operation.operatorName, "*"))
		{
			result = [leftOperand operatorMultiply:rightOperand];
		}
		else if(streq(operation.operatorName, "/"))
		{
			result = [leftOperand operatorDivide:rightOperand];
		}
		else if(streq(operation.operatorName, "^"))
		{
			result = [leftOperand operatorPower:rightOperand];
		}
		
		[pool replaceObjectAtIndex:operation.originalPosition withObject:result];
		[pool replaceObjectAtIndex:operation.originalPosition + 1 withObject:result];
	}
	
	return [pool objectAtIndex:operations[numberOfOperations - 1].originalPosition];
}

#pragma mark - Implementing <STFunction>

- (BOOL)evaluatesOwnArguments
{
	return YES;
}

- (STScope *)superscope
{
	return nil;
}

#pragma mark -

- (id)applyWithArguments:(STList *)message inScope:(STScope *)scope
{
	if(message.count == 0)
		STRaiseIssue(message.creationLocation, @"malformed message to %@", self);
	
	NSMutableString *selectorString = [NSMutableString string];
	NSMutableArray *parameters = [NSMutableArray array];
	
	BOOL isLookingForLabel = YES;
	for (id component in message)
	{
		if(isLookingForLabel)
		{
			[selectorString appendString:[component string]];
		}
		else
		{
			[parameters addObject:STEvaluate(component, scope)];
		}
		
		isLookingForLabel = !isLookingForLabel;
	}
	
	return STObjectBridgeSend(self, NSSelectorFromString(selectorString), parameters, scope);
}

#pragma mark - Operators

- (id)operatorAdd:(id)rightOperand
{
	[NSException raise:NSInternalInconsistencyException format:@"abstract operator"];
	return STNull;
}

- (id)operatorSubtract:(id)rightOperand
{
	[NSException raise:NSInternalInconsistencyException format:@"abstract operator"];
	return STNull;
}

- (id)operatorMultiply:(id)rightOperand
{
	[NSException raise:NSInternalInconsistencyException format:@"abstract operator"];
	return STNull;
}

- (id)operatorDivide:(id)rightOperand
{
	[NSException raise:NSInternalInconsistencyException format:@"abstract operator"];
	return STNull;
}

- (id)operatorPower:(id)rightOperand
{
	[NSException raise:NSInternalInconsistencyException format:@"abstract operator"];
	return STNull;
}

@end
