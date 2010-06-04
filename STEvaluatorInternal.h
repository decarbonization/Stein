/*
 *  STEvaluatorInternal.h
 *  stein
 *
 *  Created by Peter MacWhinnie on 2009/12/22.
 *  Copyright 2009 Stein Language. All rights reserved.
 *
 */

#pragma once

#import <Cocoa/Cocoa.h>
#import "STEvaluator.h"

@class STList;

/*!
 @function
 @abstract		Evaluate a specified list with a specified evaluator within a specified scope.
 @param			self	The evaluator to evaluate the list with.
 @param			list	The list to evaluate.
 @param			scope	The scope to evaluate the list in.
 @result		The result of evaluating the list.
 @discussion	This function is effectively a method on STEvaluator, it is simply in the form of a function because it is called very often and the overhead of messaging can be quite fatiguing.
 */
ST_EXTERN id __STEvaluateList(STEvaluator *self, STList *list, STScope *scope);

/*!
 @function
 @abstract		Evaluate an expression within a specified scope, returning the result.
 @discussion	This function is effectively a method on STEvaluator, it is simply in the form of a function because it is called very often and the overhead of messaging can be quite fatiguing.
 */
ST_EXTERN id __STEvaluateExpression(STEvaluator *self, id expression, STScope *scope);

#pragma mark -

/*!
 @function
 @abstract		Get the selector and arguments for a list describing a message.
 @discussion	All parameters are required.
 */
ST_INLINE void MessageListGetSelectorAndArguments(STEvaluator *evaluator, STScope *scope, STList *list, SEL *outSelector, NSArray **outArguments)
{
	NSCParameterAssert(evaluator);
	NSCParameterAssert(scope);
	
	if(!outSelector && !outArguments)
		return;
	
	NSMutableString *selectorString = [NSMutableString string];
	NSMutableArray *evaluatedArguments = [NSMutableArray array];
	
	NSUInteger index = 0;
	for (id expression in list)
	{
		//If it's even, it's part of the selector
		if((index % 2) == 0)
			[selectorString appendString:[expression string]];
		else
			[evaluatedArguments addObject:__STEvaluateExpression(evaluator, expression, scope)];
		
		index++;
	}
	
	if(outSelector) *outSelector = NSSelectorFromString(selectorString);
	if(outArguments) *outArguments = evaluatedArguments;
}
