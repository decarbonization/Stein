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
 @abstract		Send a message with a specified target, and a specified arguments list, within the context of a specified scope.
 @param			self		The evaluator that is sending the message.
 @param			target		The target of the message.
 @param			arguments	A list whose even values are selector labels, and whose odd values are expressions suitable
							for passing along with the message described by the selector labels. May not be nil.
 @param			scope		The scope to evaluate the message in.
 @result		The result of sending the message.
 @discussion	This function is effectively a method on STEvaluator, it is simply in the form of a function because it is called very often and the overhead of messaging can be quite fatiguing.
 */
ST_EXTERN id __STSendMessageWithTargetAndArguments(STEvaluator *self, id target, STList *arguments, NSMutableDictionary *scope);

/*!
 @function
 @abstract		Evaluate a specified list with a specified evaluator within a specified scope.
 @param			self	The evaluator to evaluate the list with.
 @param			list	The list to evaluate.
 @param			scope	The scope to evaluate the list in.
 @result		The result of evaluating the list.
 @discussion	This function is effectively a method on STEvaluator, it is simply in the form of a function because it is called very often and the overhead of messaging can be quite fatiguing.
 */
ST_EXTERN id __STEvaluateList(STEvaluator *self, STList *list, NSMutableDictionary *scope);

/*!
 @function
 @abstract		Evaluate an expression within a specified scope, returning the result.
 @discussion	This function is effectively a method on STEvaluator, it is simply in the form of a function because it is called very often and the overhead of messaging can be quite fatiguing.
 */
ST_EXTERN id __STEvaluateExpression(STEvaluator *self, id expression, NSMutableDictionary *scope);
