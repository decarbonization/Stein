//
//  STObjectBridge.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STObjectBridge.h"

#import "STTypeBridge.h"
#import "STFunctionInvocation.h"
#import <objc/objc-runtime.h>

#import "STList.h"
#import "STSymbol.h"

#import "STClosure.h"
#import "STNativeFunctionWrapper.h"
#import "STEvaluatorInternal.h"

/*!
 @function
 @abstract		Determines whether or not a specified selector is exempt from null messaging.
 @discussion	Under normal circumstances sending a message to null will result in null, however
				our control flow operators are implemented as messages, and it would be very bad
				if they were to stop working even if the receiver is null.
 */
ST_INLINE BOOL IsSelectorExemptFromNullMessaging(SEL selector)
{
	return (selector == @selector(ifTrue:) || selector == @selector(ifTrue:ifFalse:) ||
			selector == @selector(ifFalse:) || selector == @selector(ifFalse:ifTrue:) ||
			selector == @selector(whileTrue:) || selector == @selector(whileFalse:) ||
			selector == @selector(match:));
}

id STObjectBridgeSend(id target, SEL selector, NSArray *arguments)
{
	NSCParameterAssert(selector);
	NSCParameterAssert(arguments);
	
	if(!IsSelectorExemptFromNullMessaging(selector) && (!target || (target == STNull)))
		return STNull;
	
	NSMethodSignature *targetMethodSignature = [target methodSignatureForSelector:selector];
	if(!targetMethodSignature)
		[target doesNotRecognizeSelector:selector];
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:targetMethodSignature];
	[invocation setTarget:target];
	[invocation setSelector:selector];
	
	NSUInteger numberOfArguments = [targetMethodSignature numberOfArguments];
	for (NSUInteger index = 2; index < numberOfArguments; index++)
	{
		const char *argumentType = [targetMethodSignature getArgumentTypeAtIndex:index];
		Byte argumentBuffer[STTypeBridgeGetSizeOfObjCType(argumentType)];
		
		STTypeBridgeConvertObjectIntoType([arguments objectAtIndex:index - 2], 
										  argumentType, 
										  (void **)&argumentBuffer);
		
		[invocation setArgument:argumentBuffer atIndex:index];
	}
	
	[invocation invoke];
	
	const char *returnType = [targetMethodSignature methodReturnType];
	
	//If the method returns void, there's nothing waiting for us in the buffer.
	if(returnType[0] == 'v')
		return target;
	
	Byte returnBuffer[STTypeBridgeGetSizeOfObjCType(returnType)];
	[invocation getReturnValue:returnBuffer];
	
	return STTypeBridgeConvertValueOfTypeIntoObject(returnBuffer, returnType);
}

id STObjectBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments)
{
	NSCParameterAssert(superclass);
	NSCParameterAssert(selector);
	NSCParameterAssert(arguments);
	
	if(!IsSelectorExemptFromNullMessaging(selector) && (!target || (target == STNull)))
		return STNull;
	
	NSCAssert2([target isKindOfClass:superclass], 
			   @"%@ is not a descendent of %@", [target class], superclass);
	
	//Look up the selector and the method
	Method method = class_getInstanceMethod(superclass, selector);
	if(!method)
		method = class_getClassMethod(superclass, selector);
	
	//If we couldn't find the method, then the superclass doesn't have the method.
	if(!method)
		[superclass doesNotRecognizeSelector:selector];
	
	//Create the function invocation
	NSMethodSignature *functionSignature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
	
	STFunctionInvocation *invocation = [[[STFunctionInvocation alloc] initWithFunction:method_getImplementation(method) 
																			 signature:functionSignature] autorelease];
	[invocation setArgument:&target atIndex:0];
	[invocation setArgument:&selector atIndex:1];
	
	NSUInteger numberOfArguments = [functionSignature numberOfArguments];
	for (NSUInteger index = 2; index < numberOfArguments; index++)
	{
		const char *argumentType = [functionSignature getArgumentTypeAtIndex:index];
		Byte argumentBuffer[STTypeBridgeGetSizeOfObjCType(argumentType)];
		
		STTypeBridgeConvertObjectIntoType([arguments objectAtIndex:index - 2], 
										  argumentType, 
										  (void **)&argumentBuffer);
		
		[invocation setArgument:argumentBuffer atIndex:index];
	}
	
	[invocation apply];
	
	const char *returnType = [functionSignature methodReturnType];
	
	//If the method returns void, there's nothing waiting for us in the buffer.
	if(returnType[0] == 'v')
		return target;
	
	void *returnValue = NULL;
	[invocation getReturnValue:&returnValue];
	
	return STTypeBridgeConvertValueOfTypeIntoObject(returnValue, [functionSignature methodReturnType]);
}

#pragma mark -

NSString *const kSTClassTrackedFunctionsKey = @"STClassTrackedFunctions";

void STClassBeginTrackingFunctionWrapperForSelector(Class class, STNativeFunctionWrapper *wrapper, SEL selector)
{
	NSCParameterAssert(class);
	NSCParameterAssert(wrapper);
	
	NSMutableDictionary *trackedFunctions = objc_getAssociatedObject(class, kSTClassTrackedFunctionsKey);
	if(!trackedFunctions)
	{
		trackedFunctions = [NSMutableDictionary new];
		objc_setAssociatedObject(class, kSTClassTrackedFunctionsKey, trackedFunctions, OBJC_ASSOCIATION_RETAIN);
	}
	
	[trackedFunctions setObject:wrapper forKey:NSStringFromSelector(selector)];
}

void STClassStopTrackingFunctionWrapperForSelector(Class class, SEL selector)
{
	NSCParameterAssert(class);
	NSCParameterAssert(selector);
	
	NSMutableDictionary *trackedFunctions = objc_getAssociatedObject(class, kSTClassTrackedFunctionsKey);
	if(!trackedFunctions)
		return;
	
	[trackedFunctions removeObjectForKey:NSStringFromSelector(selector)];
}

BOOL STClassIsTrackingFunctionWrapperForSelector(Class class, SEL selector)
{
	NSCParameterAssert(class);
	NSCParameterAssert(selector);
	
	NSMutableDictionary *trackedFunctions = objc_getAssociatedObject(class, kSTClassTrackedFunctionsKey);
	if(!trackedFunctions)
		return NO;
	
	return [[trackedFunctions allKeys] containsObject:NSStringFromSelector(selector)];
}

#pragma mark -

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
	
	
	STEvaluator *evaluator = list.evaluator;
	STClosure *closure = [[STClosure alloc] initWithPrototype:prototype 
											forImplementation:implementation 
												fromEvaluator:evaluator 
													  inScope:nil];
	closure.superclass = [class superclass];
	
	const char *typeSignature = [typeSignatureString UTF8String];
	STNativeFunctionWrapper *nativeFunction = [[STNativeFunctionWrapper alloc] initWithFunction:closure 
																					  signature:[NSMethodSignature signatureWithObjCTypes:typeSignature]];
	IMP implementationFunction = nativeFunction.functionPointer;
	if(isInstanceMethod)
	{
		if(!class_addMethod(class, selector, implementationFunction, typeSignature))
		{
			Method existingMethod = class_getInstanceMethod(class, selector);
			method_setImplementation(existingMethod, implementationFunction);
		}
	}
	else
	{
		if(!class_addMethod(objc_getMetaClass(class_getName(class)), selector, implementationFunction, typeSignature))
		{
			Method existingMethod = class_getClassMethod(class, selector);
			method_setImplementation(existingMethod, implementationFunction);
		}
	}
	
	STClassBeginTrackingFunctionWrapperForSelector(class, nativeFunction, selector);
}

#pragma mark -

void STExtendClass(Class classToExtend, STList *expressions)
{
	NSCParameterAssert(classToExtend);
	NSCParameterAssert(expressions);
	
	STEvaluator *evaluator = nil;
	NSMutableDictionary *scope = nil;
	for (id expression in expressions)
	{
		if([expression isKindOfClass:[STList class]])
		{
			id head = [expression head];
			if([head isEqualTo:@"+"])
			{
				AddMethodFromClosureToClass([expression tail], NO, classToExtend);
			}
			else if([head isEqualTo:@"-"])
			{
				AddMethodFromClosureToClass([expression tail], YES, classToExtend);
			}
			else
			{
				if(!evaluator)
					evaluator = expressions.evaluator;
				
				if(!scope)
					scope = [evaluator scopeWithEnclosingScope:nil];
				
				SEL selector = nil;
				NSArray *arguments = nil;
				MessageListGetSelectorAndArguments(evaluator, scope, expression, &selector, &arguments);
				STObjectBridgeSend(classToExtend, selector, arguments);
			}
		}
	}
}

#pragma mark -

BOOL STUndefineClass(Class classToUndefine)
{
	NSCParameterAssert(classToUndefine);
	
	objc_disposeClassPair(classToUndefine);
	
	return YES;
}

BOOL STResetClass(Class classToReset)
{
	//TODO: Implement.
	return NO;
}

Class STDefineClass(NSString *subclassName, Class superclass, STList *expressions)
{
	NSCParameterAssert(subclassName);
	NSCParameterAssert(superclass);
	
	Class newClass = objc_allocateClassPair(superclass, [subclassName UTF8String], 0);
	if(newClass)
		objc_registerClassPair(newClass);
	else
		newClass = objc_getClass([subclassName UTF8String]);
	
	if(expressions)
		STExtendClass(newClass, expressions);
	
	return newClass;
}
