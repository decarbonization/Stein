//
//  NSObject+SteinClassAdditions.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSObject+SteinClassAdditions.h"
#import <objc/objc-runtime.h>

#import "STList.h"
#import "STSymbol.h"

#import "STClosure.h"
#import "STTypeBridge.h"

static NSString *const kNSObjectAdditionalIvarsTableKey = @"NSObject_additionalIvarsTable";

@implementation NSObject (SteinClassAdditions)

#pragma mark -
#pragma mark Extension

static void GetMethodDefinitionFromListWithTypes(STList *list, SEL *outSelector, STList **outPrototype, NSString **outTypeSignature, STList **outImplementation)
{
	NSMutableString *selectorString = [NSMutableString string];
	STList *prototype = [STList listWithArray:[NSArray arrayWithObjects:@"self", @"_cmd", nil]];
	
	NSString *returnType = [[[list head] head] string];
	NSMutableString *typeSignature = [NSMutableString stringWithFormat:@"%@@:", STTypeBridgeGetObjCTypeForHumanReadableType(returnType)];
	
	STList *implementation = nil;
	
	enum {
		kLookingForSelector = 0,
		kLookingForType,
		kLookingForPrototypePiece,
	} whatWereLookingFor = kLookingForSelector;
	for (id expression in [list tail])
	{
		if([expression isKindOfClass:[STList class]] && [expression isQuoted])
		{
			implementation = expression;
			implementation.isDoConstruct = NO;
			implementation.isQuoted = NO;
			break;
		}
		
		switch (whatWereLookingFor)
		{
			case kLookingForSelector:
				[selectorString appendString:[expression string]];
				break;
				
			case kLookingForType:
				[typeSignature appendString:STTypeBridgeGetObjCTypeForHumanReadableType([[expression head] string])];
				break;
				
			case kLookingForPrototypePiece:
				[prototype addObject:[expression string]];
				break;
				
			default:
				break;
		}
		
		whatWereLookingFor++;
		if(whatWereLookingFor > kLookingForPrototypePiece)
			whatWereLookingFor = kLookingForSelector;
	}
	
	*outSelector = NSSelectorFromString(selectorString);
	*outPrototype = prototype;
	*outTypeSignature = typeSignature;
	*outImplementation = implementation;
}

static void GetMethodDefinitionFromListWithoutTypes(STList *list, SEL *outSelector, STList **outPrototype, NSString **outTypeSignature, STList **outImplementation)
{
	NSMutableString *selectorString = [NSMutableString string];
	STList *prototype = [STList listWithArray:[NSArray arrayWithObjects:@"self", @"_cmd", nil]];
	NSMutableString *typeSignature = [NSMutableString stringWithString:@"@@:"];
	STList *implementation = nil;
	
	NSUInteger index = 0;
	for (id expression in list)
	{
		if([expression isKindOfClass:[STList class]])
		{
			implementation = expression;
			implementation.isDoConstruct = NO;
			implementation.isQuoted = NO;
			break;
		}
		
		if((index % 2) == 0)
		{
			[selectorString appendString:[expression string]];
		}
		else
		{
			[typeSignature appendString:@"@"];
			[prototype addObject:[expression string]];
		}
		
		index++;
	}
	
	*outSelector = NSSelectorFromString(selectorString);
	*outPrototype = prototype;
	*outTypeSignature = typeSignature;
	*outImplementation = implementation;
}

static void AddMethodFromClosureToClass(STList *list, BOOL isInstanceMethod, Class class)
{
	SEL selector = NULL;
	STList *prototype = nil;
	NSString *typeSignatureString = nil;
	STList *implementation = nil;
	
	BOOL isTypeInformationIncluded = [[list head] isKindOfClass:[STList class]];
	if(isTypeInformationIncluded)
		GetMethodDefinitionFromListWithTypes(list, &selector, &prototype, &typeSignatureString, &implementation);
	else
		GetMethodDefinitionFromListWithoutTypes(list, &selector, &prototype, &typeSignatureString, &implementation);
	
	const char *typeSignature = [typeSignatureString UTF8String];
	STClosure *closure = [[STClosure alloc] initWithPrototype:prototype 
											forImplementation:implementation 
												withSignature:[NSMethodSignature signatureWithObjCTypes:typeSignature] 
												fromEvaluator:list.evaluator 
													  inScope:nil];
	closure.superclass = [class superclass];
	[[NSGarbageCollector defaultCollector] disableCollectorForPointer:closure];
	
	if(isInstanceMethod)
		class_addMethod(class, selector, (IMP)closure.functionPointer, typeSignature);
	else
		class_addMethod(objc_getMetaClass(class_getName(class)), selector, (IMP)closure.functionPointer, typeSignature);
}

#pragma mark -

+ (Class)extend:(STClosure *)expressions
{
	for (id expression in expressions.implementation)
	{
		if([expression isKindOfClass:[STList class]])
		{
			id head = [expression head];
			if([head isEqualTo:@"+"])
				AddMethodFromClosureToClass([expression tail], NO, self);
			else if([head isEqualTo:@"-"])
				AddMethodFromClosureToClass([expression tail], YES, self);
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Subclassing

+ (Class)subclass:(NSString *)subclassName
{
	return [self subclass:subclassName where:nil];
}

+ (Class)subclass:(NSString *)subclassName where:(STClosure *)expressions
{
	NSParameterAssert(subclassName);
	
	Class newClass = objc_allocateClassPair(self, [subclassName UTF8String], 0);
	objc_registerClassPair(newClass);
	
	for (id expression in expressions.implementation)
	{
		if([expression isKindOfClass:[STList class]])
		{
			id head = [expression head];
			if([head isEqualTo:@"+"])
				AddMethodFromClosureToClass([expression tail], NO, newClass);
			else if([head isEqualTo:@"-"])
				AddMethodFromClosureToClass([expression tail], YES, newClass);
		}
	}
	
	return newClass;
}

#pragma mark -
#pragma mark Ivars

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
	Byte buffer[STTypeBridgeSizeofObjCType(ivarTypeEncoding)];
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

@end
