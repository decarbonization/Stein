//
//  STInterpreter.h
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STScope;

/*!
 @abstract		Evaluates a parsed expression in a specified scope.
 @param			parsedExpression	The expression to evaluate. Optional.
 @param			scope				The scope to evaluate the expression in. Optional.
 @result		The result of evaluating the parsed-expression.
 @discussion	Any exceptions raised during a call to STEvaluate are encapsulated in SteinException
				objects and rethrown. This allows more precise error reporting.
 */
ST_EXTERN id STEvaluate(id parsedExpression, STScope *scope);
