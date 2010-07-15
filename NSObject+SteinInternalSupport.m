//
//  NSObject+SteinInternalSupport.m
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
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
	
	
	//Overrides for kSTUseUniqueRuntimeClassNames
	method_exchangeImplementations(class_getClassMethod(self, @selector(className)), 
								   class_getClassMethod(self, @selector(stein_className)));
	
	method_exchangeImplementations(class_getClassMethod(self, @selector(description)), 
								   class_getClassMethod(self, @selector(stein_description)));
	
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(description)), 
								   class_getInstanceMethod(self, @selector(stein_description)));
}

#pragma mark -
#pragma mark • Overrides for <STMethodMissing>

+ (BOOL)stein_respondsToSelector:(SEL)selector
{
	return [self stein_respondsToSelector:selector] || [self canHandleMissingMethodWithSelector:selector];
}

- (BOOL)stein_respondsToSelector:(SEL)selector
{
	return [self stein_respondsToSelector:selector] || [self canHandleMissingMethodWithSelector:selector];
}

#pragma mark -
#pragma mark • Overrides for kSTUseUniqueRuntimeClassNames

+ (NSString *)stein_className
{
	return [self valueForIvarNamed:@"$steinClassName"] ?: [self stein_className];
}

- (NSString *)stein_className
{
	return [[self class] stein_className];
}

+ (NSString *)stein_description
{
	return [self className];
}

- (NSString *)stein_description
{
	return [NSString stringWithFormat:@"<%@:%p>", [[self class] className], self];
}

#pragma mark -
#pragma mark • Overrides for Ivar

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
#pragma mark Implementing <STMethodMissing>

+ (BOOL)canHandleMissingMethodWithSelector:(SEL)selector
{
	return NO;
}

+ (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope
{
	NSLog(@"[%s %s] called without concrete implementation. Did you forget to override it in your subclass?", class_getName([self class]), sel_getName(selector));
	return STNull;
}

#pragma mark -

- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector
{
	return NO;
}

- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope
{
	NSLog(@"[%s %s] called without concrete implementation. Did you forget to override it in your subclass?", class_getName([self class]), sel_getName(selector));
	return STNull;
}

#pragma mark -
#pragma mark Implementing <STFunction>

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

#pragma mark -
#pragma mark Operators

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
