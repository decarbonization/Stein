//
//  NSObject+SteinMessaging.m
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "NSObject+SteinMessaging.h"
#import "NSObject+Stein.h"

#import "STObjectBridge.h"
#import "STInterpreter.h"

#import <objc/message.h>

@implementation NSObject (SteinMessaging)

#pragma mark Overrides

+ (void)load
{
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(respondsToSelector:)), 
								   class_getInstanceMethod(self, @selector(stein_respondsToSelector:)));
	
	method_exchangeImplementations(class_getClassMethod(self, @selector(respondsToSelector:)), 
								   class_getClassMethod(self, @selector(stein_respondsToSelector:)));
}

+ (BOOL)stein_respondsToSelector:(SEL)selector
{
	return [self stein_respondsToSelector:selector] || [self canHandleMissingMethodWithSelector:selector];
}

- (BOOL)stein_respondsToSelector:(SEL)selector
{
	return [self stein_respondsToSelector:selector] || [self canHandleMissingMethodWithSelector:selector];
}

#pragma mark -
#pragma mark <STFunction>

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

@end
