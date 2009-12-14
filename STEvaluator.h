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
	NSMutableDictionary *mRootScope;
}
#pragma mark Root Scope

- (void)setValue:(id)value forKeyInRootScope:(NSString *)key;
- (id)valueForKeyInRootScope:(NSString *)key;

#pragma mark -

@property (readonly) NSDictionary *rootScope;

#pragma mark -
#pragma mark Scope Creation

/*!
 @method
 @abstract	Create a new scope with a specified enclosing scope.
 @param		enclosingScope	The scope that encloses the sope about to be created. If nil the receiver's root scope will be used.
 @result	A new autoreleased dictionary ready for use with STEvaluator.
 */
- (NSMutableDictionary *)scopeWithEnclosingScope:(NSMutableDictionary *)enclosingScope;

#pragma mark -
#pragma mark Parsing & Evaluation

- (NSArray *)parseString:(NSString *)string;
- (id)evaluateExpression:(id)expression inScope:(NSMutableDictionary *)scope;

#pragma mark -

- (id)parseAndEvaluateString:(NSString *)string;
@end
