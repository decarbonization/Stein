//
//  STFunction.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STEvaluator.h>

@class STList;
@protocol STFunction < NSObject >

- (BOOL)evaluatesOwnArguments;
- (STEvaluator *)evaluator;

- (id)applyWithArguments:(STList *)arguments inScope:(NSMutableDictionary *)scope;

@optional

- (NSMutableDictionary *)superscope;

@end

ST_INLINE id STFunctionApply(id < STFunction > function, STList *arguments)
{
	STEvaluator *evaluator = [function evaluator];
	
	id superscope = [function respondsToSelector:@selector(superscope)]? [function superscope] : nil;
	NSMutableDictionary *scope = [evaluator scopeWithEnclosingScope:superscope];
	
	return [function applyWithArguments:arguments inScope:scope];
}
