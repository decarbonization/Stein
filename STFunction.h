//
//  STFunction.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STList, STEvaluator;
@protocol STFunction

- (BOOL)evaluatesOwnArguments;
- (STEvaluator *)evaluator;

- (id)applyWithArguments:(STList *)arguments inScope:(NSMutableDictionary *)scope;

@end
