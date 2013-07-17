//
//  STInterpreter.h
//  stein
//
//  Created by Kevin MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#ifndef STInterpreter_h
#define STInterpreter_h 1

#import <Foundation/Foundation.h>

@class STScope;

///Evaluates a parsed expression in a specified scope.
///
/// \param		parsedExpression	The expression to evaluate. Optional.
/// \param		scope				The scope to evaluate the expression in. Optional.
///
/// \result		The result of evaluating the parsed-expression.
///
///Any exceptions raised during a call to STEvaluate are encapsulated in SteinException
///objects and rethrown. This allows more precise error reporting.
ST_EXTERN id STEvaluate(id parsedExpression, STScope *scope);

///Returns the shared root scope, creating it if it does not exist.
ST_EXTERN STScope *STGetSharedRootScope();

#endif /* STInterpreter_h */