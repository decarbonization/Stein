//
//  STMessageBridge.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STMessageBridge.h"
#import "STTypeBridge.h"
#import "STFunctionInvocation.h"
#import <objc/objc-runtime.h>

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

id STMessageBridgeSend(id target, SEL selector, NSArray *arguments)
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
		Byte argumentBuffer[STTypeBridgeSizeofObjCType(argumentType)];
		
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
	
	Byte returnBuffer[STTypeBridgeSizeofObjCType(returnType)];
	[invocation getReturnValue:returnBuffer];
	
	return STTypeBridgeConvertValueOfTypeIntoObject(returnBuffer, returnType);
}

id STMessageBridgeSendSuper(id target, Class superclass, SEL selector, NSArray *arguments)
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
		Byte argumentBuffer[STTypeBridgeSizeofObjCType(argumentType)];
		
		STTypeBridgeConvertObjectIntoType([arguments objectAtIndex:index - 2], 
										  argumentType, 
										  (void **)&argumentBuffer);
		
		[invocation setArgument:argumentBuffer atIndex:index];
	}
	
	[invocation invoke];
	
	const char *returnType = [functionSignature methodReturnType];
	
	//If the method returns void, there's nothing waiting for us in the buffer.
	if(returnType[0] == 'v')
		return target;
	
	void *returnValue = NULL;
	[invocation getReturnValue:&returnValue];
	
	return STTypeBridgeConvertValueOfTypeIntoObject(returnValue, [functionSignature methodReturnType]);
}
