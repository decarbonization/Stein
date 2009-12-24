//
//  STEvaluator.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 @const
 @abstract	The key used to store and access the enclosing scope for a scope created by an STEvaluator object.
 */
ST_EXTERN NSString *const kSTEvaluatorEnclosingScopeKey;

/*!
 @const
 @abstract	The key used to store and access the superclass of an class.
 */
ST_EXTERN NSString *const kSTEvaluatorSuperclassKey;


/*!
 @class
 @abstract	The STEvaluator class serves as the interpreter portion of the Stein programming language.
 */
@interface STEvaluator : NSObject
{
	/* owner */	NSMutableDictionary *mRootScope;
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

/*!
 @method
 @abstract	Set the value for a variable with a specified name in a specified scope.
 */
- (void)setObject:(id)object forVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope;

/*!
 @method
 @abstract	Look up the value for a variable with a specified name in a specified scope.
 */
- (id)objectForVariableNamed:(NSString *)name inScope:(NSMutableDictionary *)scope;

#pragma mark -

/*!
 @property
 @abstract	The root scope of the evaluator.
 */
@property (readonly) NSMutableDictionary *rootScope;

#pragma mark -
#pragma mark Parsing & Evaluation

/*!
 @method
 @abstract	Parse a string and return an array of compiled expressions.
 */
- (NSArray *)parseString:(NSString *)string;

/*!
 @method
 @abstract	Evaluate an expression within a specified scope.
 */
- (id)evaluateExpression:(id)expression inScope:(NSMutableDictionary *)scope;

#pragma mark -

/*!
 @method
 @abstract	Parse a string and evaluate the resulting compiled expressions, returning the result of the last expression.
 */
- (id)parseAndEvaluateString:(NSString *)string;

@end
