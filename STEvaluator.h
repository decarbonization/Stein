//
//  STEvaluator.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface STEvaluator : NSObject
{
	NSMutableDictionary *mRootContext;
}
#pragma mark Root Context

- (void)setValue:(id)value forKeyInRootContext:(NSString *)key;
- (id)valueForKeyInRootContext:(NSString *)key;

#pragma mark -

@property (readonly) NSDictionary *rootContext;

#pragma mark -
#pragma mark Parsing & Evaluation

- (NSArray *)parseString:(NSString *)string;
- (id)evaluateExpression:(id)expression;

#pragma mark -

- (id)parseAndEvaluateString:(NSString *)string;
@end
