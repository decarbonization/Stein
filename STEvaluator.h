//
//  STEvaluator.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

ST_EXTERN NSString *const kSTEvaluatorEnclosingScopeKey;
ST_EXTERN NSString *const kSTEvaluatorSuperclassKey;

@interface STEvaluator : NSObject
{
	NSMutableDictionary *mRootScope;
}

#pragma mark Scoping

/*!
 @method
 @abstract	Create a new scope with a specified enclosing scope.
 @param		enclosingScope	The scope that encloses the sope about to be created. If nil the receiver's root scope will be used.
 @result	A new autoreleased dictionary ready for use with STEvaluator.
 */
- (NSMutableDictionary *)scopeWithEnclosingScope:(NSMutableDictionary *)enclosingScope;

#pragma mark -

- (void)setObject:(id)object forVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope;
- (id)objectForVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope;

#pragma mark -

@property (readonly) NSMutableDictionary *rootScope;

#pragma mark -
#pragma mark Parsing & Evaluation

- (NSArray *)parseString:(NSString *)string;
- (id)evaluateExpression:(id)expression inScope:(NSMutableDictionary *)scope;

#pragma mark -

- (id)parseAndEvaluateString:(NSString *)string;
@end
