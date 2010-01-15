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
 @const
 @abstract	The bundle Info.plist key used to specify that a bundle is pure Stein, and contains no native code.
 */
ST_EXTERN NSString *const kSTBundleIsPureSteinKey;


@class STSymbol;

/*!
 @class
 @abstract	The STEvaluator class serves as the interpreter portion of the Stein programming language.
 */
@interface STEvaluator : NSObject
{
	NSMutableDictionary *mRootScope;
	NSMutableArray *mSearchPaths;
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
- (void)setObject:(id)object forVariableNamed:(STSymbol *)name inScope:(NSMutableDictionary *)scope;

/*!
 @method
 @abstract	Look up the value for a variable with a specified name in a specified scope.
 */
- (id)objectForVariableNamed:(STSymbol *)name inScope:(NSMutableDictionary *)scope;

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

#pragma mark -
#pragma mark Importing

/*!
 @property
 @abstract	The paths the evaluator searches when it is attempting to import a file, or bundle.
 */
@property (readonly) NSArray *searchPaths;

#pragma mark -

/*!
 @method
 @abstract	Add a new search path to the receiver.
 @param		searchPath	May not be nil.
 */
- (void)addSearchPath:(NSString *)searchPath;

/*!
 @method
 @abstract		Remove a search path from the receiver.
 @param			searchPath	May not be nil.
 @discussion	This method does nothing if the receiver does not contain the search path.
 */
- (void)removeSearchPath:(NSString *)searchPath;

#pragma mark -

/*!
 @method
 @abstract	Import the contents of a string into the evaluator.
 */
- (BOOL)import:(NSString *)location;

@end
