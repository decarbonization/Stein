//
//  STBuiltInFunctions.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

#pragma once

#define STBuiltInFunctionExport(name) ST_EXTERN STBuiltInFunction *STBuiltInFunction##name(STEvaluator *evaluator)
#define STBuiltInFunctionDefine(name, evaluates, ...) STBuiltInFunction *STBuiltInFunction##name(STEvaluator *evaluator) { return [STBuiltInFunction builtInFunctionWithImplementation:(__VA_ARGS__) evaluatesOwnArguments:evaluates evaluator:evaluator]; }
#define STBuiltInFunctionWithNameForEvaluator(name, evaluator) STBuiltInFunction##name(evaluator)

#pragma mark -

@class STEvaluator, STList;
typedef id(^STBuiltInFunctionImplementation)(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope);

@interface STBuiltInFunction : NSObject < STFunction >
{
	/* owner */	STBuiltInFunctionImplementation mImplementation;
	/* weak */	STEvaluator *mEvaluator;
	/* n/a */	BOOL mEvaluatesOwnArguments;
}
- (id)initWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments evaluator:(STEvaluator *)evaluator;
+ (STBuiltInFunction *)builtInFunctionWithImplementation:(STBuiltInFunctionImplementation)implementation evaluatesOwnArguments:(BOOL)evaluatesOwnArguments evaluator:(STEvaluator *)evaluator;

@property (readonly, copy) STBuiltInFunctionImplementation implementation;
@property (readonly) STEvaluator *evaluator;

@property (readonly) BOOL evaluatesOwnArguments;
@end

#pragma mark -
#pragma mark Basic Math

STBuiltInFunctionExport(Add);
STBuiltInFunctionExport(Subtract);
STBuiltInFunctionExport(Multiply);
STBuiltInFunctionExport(Divide);
STBuiltInFunctionExport(Modulo);
STBuiltInFunctionExport(Power);

#pragma mark -
#pragma mark Comparisons

STBuiltInFunctionExport(Equal);
STBuiltInFunctionExport(NotEqual);
STBuiltInFunctionExport(LessThan);
STBuiltInFunctionExport(LessThanOrEqual);
STBuiltInFunctionExport(GreaterThan);
STBuiltInFunctionExport(GreaterThanOrEqual);

#pragma mark -
#pragma mark Logical Operations

STBuiltInFunctionExport(Or);
STBuiltInFunctionExport(And);
STBuiltInFunctionExport(Not);

#pragma mark -
#pragma mark Bridging

STBuiltInFunctionExport(BridgeFunction);
STBuiltInFunctionExport(BridgeConstant);
