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
			implementation.isQuoted = NO;
			break;
		}
		
		switch (whatWereLookingFor)
		{
			case kLookingForSelector:
				[selectorString appendString:[expression string]];
				break;
				
			case kLookingForType:
				[typeSignature appendString:STTypeBridgeGetObjCTypeForHumanReadableType([expression head])];
				break;
				
			case kLookingForPrototypePiece:
				[prototype addObject:expression];
				break;
				
			default:
				break;
		}
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
			[prototype addObject:expression];
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
												fromEvaluator:list.evaluator];
	[[NSGarbageCollector defaultCollector] disableCollectorForPointer:closure];
	
	if(isInstanceMethod)
		class_addMethod(class, selector, (IMP)closure.functionPointer, typeSignature);
	else
		class_addMethod(objc_getMetaClass(class_getName(class)), selector, (IMP)closure.functionPointer, typeSignature);
}

#pragma mark -

+ (Class)extend:(STList *)expressions
{
	for (id expression in expressions)
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

+ (Class)subclass:(NSString *)subclassName where:(STList *)expressions
{
	NSParameterAssert(subclassName);
	
	Class newClass = objc_allocateClassPair(self, [subclassName UTF8String], 0);
	objc_registerClassPair(newClass);
	
	for (id expression in expressions)
	{
		if([expression isKindOfClass:[STList class]])
		{
			id head = [expression head];
			if([head isEqualTo:@"+"])
				AddMethodFromClosureToClass([expression tail], NO, newClass);
			else if([head isEqualTo:@"-"])
				AddMethodFromClosureToClass([expression tail], NO, newClass);
		}
	}
	
	return newClass;
}

@end
