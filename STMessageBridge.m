//
//  STMessageBridge.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STMessageBridge.h"
#import "STTypeBridge.h"

id STMessageBridgeSend(id target, SEL selector, NSArray *arguments)
{
	NSCParameterAssert(selector);
	NSCParameterAssert(arguments);
	
	if(!target || (target == (id)kCFNull))
		return (id)kCFNull;
	
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
