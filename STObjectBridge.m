//
//  STObjectBridge.m
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STObjectBridge.h"

#import "STTypeBridge.h"
#import "STFunctionInvocation.h"
#import <objc/objc-runtime.h>

#import "STList.h"
#import "STSymbol.h"

#import "STScope.h"
#import "STModule.h"
#import "STInterpreter.h"

#import "STClosure.h"
#import "STNativeFunctionWrapper.h"

#import "NSObject+SteinInternalSupport.h"

///Determines whether or not a specified selector is exempt from null messaging.
///
///Under normal circumstances sending a message to null will result in null, however
///our control flow operators are implemented as messages, and it would be very bad
///if they were to stop working even if the receiver is null.
ST_INLINE BOOL IsSelectorExemptFromNullMessaging(SEL selector)
{
	return (selector == @selector(ifTrue:) || selector == @selector(ifFalse:) || selector == @selector(ifTrue:ifFalse:) ||
			selector == @selector(whileTrue:) || selector == @selector(whileFalse:) ||
			selector == @selector(match:));
}

///Autoreleases a given object, bypassing ARC.
///
///This function should be considered dangerous outside of defined use-cases.
ST_INLINE id STAutoreleaseObject(id object)
{
    return objc_msgSend(object, NSSelectorFromString(@"autorelease"));
}

id STObjectBridgeSend(id target, SEL selector, NSArray *arguments, STScope *scope)
{
	NSCParameterAssert(selector);
	NSCParameterAssert(arguments);
	
	if(!IsSelectorExemptFromNullMessaging(selector) && STIsNull(target))
		return STNull;
	
	NSMethodSignature *targetMethodSignature = [target methodSignatureForSelector:selector];
	if(!targetMethodSignature)
	{
		if(class_respondsToSelector(object_getClass(target), @selector(canHandleMissingMethodWithSelector:)) &&
		   class_respondsToSelector(object_getClass(target), @selector(handleMissingMethodWithSelector:arguments:inScope:)))
		{
			if([target canHandleMissingMethodWithSelector:selector])
				return [target handleMissingMethodWithSelector:selector arguments:arguments inScope:scope] ?: STNull;
		}
		
		[target doesNotRecognizeSelector:selector];
	}
	
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
	
	id result = STTypeBridgeConvertValueOfTypeIntoObject(returnBuffer, returnType);
    
    //The lifecycle of objects returned from `init` or `new` methods is determined
    //by the caller. Since we don't want the caller in the script to have to worry
    //about the lifecycle of the object given back to it in the script, we autorelease
    //the object here and then return it. If these objects are meant to last beyond
    //the current scope (e.g. a function, line in the REPL, or AppKit event cycle)
    //then they will be assigned to variables, which keep the objects around.
    NSString *selectorString = NSStringFromSelector(selector);
    if([selectorString hasPrefix:@"init"] || [selectorString hasPrefix:@"new"])
        STAutoreleaseObject(result);
    
    return result;
}

id STObjectBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments, STScope *scope)
{
	NSCParameterAssert(superclass);
	NSCParameterAssert(selector);
	NSCParameterAssert(arguments);
	
	if(!IsSelectorExemptFromNullMessaging(selector) && STIsNull(target))
		return STNull;
	
	NSCAssert2([target isKindOfClass:superclass], 
			   @"%@ is not a descendent of %@", [target class], superclass);
	
	//Look up the selector and the method
	Method method = class_getInstanceMethod(superclass, selector);
	if(!method)
		method = class_getClassMethod(superclass, selector);
	
	//If we couldn't find the method, then the superclass doesn't have the method.
	if(!method)
	{
		if(class_respondsToSelector(object_getClass(target), @selector(canHandleMissingMethodWithSelector:)) &&
		   class_respondsToSelector(object_getClass(target), @selector(handleMissingMethodWithSelector:arguments:inScope:)))
		{
			struct objc_super superTarget = { target, superclass };
			if(((BOOL(*)(struct objc_super *, SEL, SEL))objc_msgSendSuper)(&superTarget, @selector(canHandleMissingMethodWithSelector:), selector))
				return objc_msgSendSuper(&superTarget, @selector(handleMissingMethodWithSelector:arguments:inScope:), selector, arguments, scope) ?: STNull;
		}
		
		[superclass doesNotRecognizeSelector:selector];
	}
	
	//Create the function invocation
	NSMethodSignature *functionSignature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
	
	STFunctionInvocation *invocation = [[STFunctionInvocation alloc] initWithFunction:method_getImplementation(method) 
																			signature:functionSignature];
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
	
	NSMutableDictionary *trackedFunctions = objc_getAssociatedObject(class, (__bridge const void *)(kSTClassTrackedFunctionsKey));
	if(!trackedFunctions)
	{
		trackedFunctions = [NSMutableDictionary new];
		objc_setAssociatedObject(class, (__bridge const void *)(kSTClassTrackedFunctionsKey), trackedFunctions, OBJC_ASSOCIATION_RETAIN);
	}
	
	[trackedFunctions setObject:wrapper forKey:NSStringFromSelector(selector)];
}

void STClassStopTrackingFunctionWrapperForSelector(Class class, SEL selector)
{
	NSCParameterAssert(class);
	NSCParameterAssert(selector);
	
	NSMutableDictionary *trackedFunctions = objc_getAssociatedObject(class, (__bridge const void *)(kSTClassTrackedFunctionsKey));
	if(!trackedFunctions)
		return;
	
	[trackedFunctions removeObjectForKey:NSStringFromSelector(selector)];
}

BOOL STClassIsTrackingFunctionWrapperForSelector(Class class, SEL selector)
{
	NSCParameterAssert(class);
	NSCParameterAssert(selector);
	
	NSMutableDictionary *trackedFunctions = objc_getAssociatedObject(class, (__bridge const void *)(kSTClassTrackedFunctionsKey));
	if(!trackedFunctions)
		return NO;
	
	return [[trackedFunctions allKeys] containsObject:NSStringFromSelector(selector)];
}

#pragma mark -

static void GetMethodDefinitionFromListWithTypes(STList *list, SEL *outSelector, STList **outPrototype, NSString **outTypeSignature, STList **outImplementation)
{
	NSMutableString *selectorString = [NSMutableString string];
	STList *prototype = [[STList alloc] initWithArray:[NSArray arrayWithObjects:@"self", @"_cmd", nil]];
	
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
		if([expression isKindOfClass:[STList class]] && ST_FLAG_IS_SET([expression flags], kSTListFlagIsQuoted))
		{
			implementation = expression;
			implementation.flags = kSTListFlagsNone;
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
	STList *prototype = [[STList alloc] initWithArray:[NSArray arrayWithObjects:@"self", @"_cmd", nil]];
	NSMutableString *typeSignature = [NSMutableString stringWithString:@"@@:"];
	STList *implementation = nil;
	
	NSUInteger index = 0;
	for (id expression in list)
	{
		if([expression isKindOfClass:[STList class]])
		{
			implementation = expression;
			implementation.flags = kSTListFlagsNone;
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
	
	
	STClosure *closure = [[STClosure alloc] initWithPrototype:prototype forImplementation:implementation inScope:nil];
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
	
	STScope *scope = nil;
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
				if(!scope)
				{
					scope = [STScope new];
					[scope setValue:classToExtend forVariableNamed:@"self" searchParentScopes:NO];
				}
				
				STEvaluate(expression, scope);
			}
		}
	}
}

#pragma mark -

BOOL STUndefineClass(Class classToUndefine, STScope *scope)
{
	NSCParameterAssert(classToUndefine);
	
	objc_disposeClassPair(classToUndefine);
	
	return YES;
}

Class STDefineClass(NSString *subclassName, Class superclass, STList *expressions, STScope *scope)
{
	NSCParameterAssert(subclassName);
	NSCParameterAssert(superclass);
	
	NSString *runtimeClassName = nil;
	if(STUseUniqueRuntimeClassNames)
	{
		if([scope valueForVariableNamed:subclassName searchParentScopes:NO])
			STRaiseIssue(expressions.creationLocation, @"Cannot redefine class %@", subclassName);
		
		runtimeClassName = [[NSUUID UUID] UUIDString];
	}
	else
	{
		if([scope isKindOfClass:[STModule class]])
			runtimeClassName = [NSString stringWithFormat:@"%@_%@", scope.name, subclassName];
		else
			runtimeClassName = subclassName;
		
		if(objc_getClass([runtimeClassName UTF8String]))
			STRaiseIssue(expressions.creationLocation, @"Cannot redefine class %@", runtimeClassName);
	}
	
	Class newClass = objc_allocateClassPair(superclass, [runtimeClassName UTF8String], 0);
	objc_registerClassPair(newClass);
	
	[scope setValue:newClass forVariableNamed:subclassName searchParentScopes:NO];
	if(STUseUniqueRuntimeClassNames)
		[newClass setValue:subclassName forIvarNamed:@"$steinClassName"];
	
	if(expressions)
		STExtendClass(newClass, expressions);
	
	return newClass;
}
