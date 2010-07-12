//
//  NSObject+SteinMessaging.m
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "NSObject+SteinMessaging.h"
#import "STObjectBridge.h"
#import "STInterpreter.h"

@implementation NSObject (SteinMessaging)

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
