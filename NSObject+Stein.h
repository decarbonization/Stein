//
//  NSObject+Stein.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STEnumerable.h>

@protocol STFunction;
@class STClosure, STRange;

/*!
 @category
 @abstract	This category adds several collections of methods to NSObject that are used extensively by Stein.
			These methods include decision making control flow constructs (ifTrue/match), class extension,
			and printing.
 */
@interface NSObject (Stein)

#pragma mark Truthiness

/*!
 @method
 @abstract	Returns whether or not the receiver is true.
 */
- (BOOL)isTrue;
+ (BOOL)isTrue;

#pragma mark -
#pragma mark If Statements

/*!
 @method
 @abstract	Ask the receiver if it's true, and then execute a block based on the receiver's truthiness.
 @param		thenClause	The block to call if the receiver is true.
 @param		elseClause	The block to call if the receiver is false.
 @result	The return value of the block that was called.
 */
- (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause;
+ (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause;

#pragma mark -

/*!
 @method
 @abstract	Ask the receiver if it's true, and then if it is execute a specified block.
 @param		thenClause	The block to call if the receiver is true.
 @result	The return value of the block that was called.
 */
- (id)ifTrue:(id < STFunction >)thenClause;
+ (id)ifTrue:(id < STFunction >)thenClause;

#pragma mark -

/*!
 @method
 @abstract	Ask the receiver if it's false, and then if it is execute a specified block.
 @param		thenClause	The block to call if the receiver is false.
 @result	The return value of the block that was called.
 */
- (id)ifFalse:(id < STFunction >)thenClause;
+ (id)ifFalse:(id < STFunction >)thenClause;

#pragma mark -
#pragma mark Matching

/*!
 @method
 @abstract	Compare the receiver against a closure containing match clauses.
 @param		matchers	A closure whose contents are lists whose heads are a value that
						the receiver can be matched against, and whose tails are expressions
						that can be evaluated under normal conditions.
 @result	The result of matching the receiver.
 */
- (id)match:(STClosure *)matchers;
+ (id)match:(STClosure *)matchers;

#pragma mark -
#pragma mark Printing

/*!
 @method
 @abstract	Returns a string that represents the contents of the receiving object that is easily readable in the context of a command prompt.
 */
- (NSString *)prettyDescription;

/*!
 @method
 @abstract	Print the receiver, using it's pretty description.
 */
- (NSString *)prettyPrint;

#pragma mark -

/*!
 @method
 @abstract	Print the receiver.
 */
- (NSString *)print;

#pragma mark -
#pragma mark Ivars

/*!
 @method
 @abstract	Sets the ivar of the receiver specified by a given key to a given value.
 @param		value	The value for the ivar identified by the key.
 @param		name	The name of one of the receiver's ivars. May not be nil.
 */
- (void)setValue:(id)value forIvarNamed:(NSString *)name;
+ (void)setValue:(id)value forIvarNamed:(NSString *)name;

/*!
 @method
 @abstract	Returns the value for the ivar identified by a given key.
 @param		name	The name of one of the receiver's ivars. May not be nil.
 @result	The value for the ivar identified by `name`.
 */
- (id)valueForIvarNamed:(NSString *)name;
+ (id)valueForIvarNamed:(NSString *)name;

#pragma mark -
#pragma mark Extension

/*!
 @method
 @abstract	Extend the receiver using a closure full of method constructs.
 */
+ (Class)extend:(STClosure *)extensions inEvaluator:(STEvaluator *)evaluator;

#pragma mark -
#pragma mark High-Level Forwarding

+ (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator;
+ (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator;

/*!
 @method
 @abstract		Returns whether the receiver will handle a missing method with a specified selector.
 @param			selector	The method which contains no known implementation in the receiver.
 @param			evaluator	The evaluator in which the missing method has been called from.
 @result		YES if the receiver can handle the selector; NO otherwise.
 @discussion	This method is invoked by the Stein runtime when an object doesn't respond to a specified selector.
 */
- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector inEvaluator:(STEvaluator *)evaluator;

/*!
 @method
 @abstract		Performs an action for a missing selector with a specified array of arguments.
 @param			selector	The method to perform an action for.
 @param			arguments	The arguments passed to the method.
 @param			evaluator	The evaluator in which the missing method has been called from.
 @result		The result of the action performed.
 @discussion	This method is invoked by the Stein runtime when -[NSObject canHandleMissingMethodWithSelector:] returns YES.
				
				The default implementation of this method simply calls -[NSObject doesNotRecognizeSelector:]
 */
- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inEvaluator:(STEvaluator *)evaluator;

@end

#pragma mark -

/*!
 @method
 @abstract	This category adds truthiness and pretty printing to NSNumber.
 */
@interface NSNumber (Stein)

- (BOOL)isTrue;
- (NSString *)prettyDescription;

- (STRange *)rangeWithLength:(NSUInteger)length;

@end

/*!
 @method
 @abstract	Pretty printing to NSString.
 */
@interface NSString (Stein)

/*!
 @method
 @abstract		Returns the receiver.
 @discussion	This method exists to allow NSString to be interchangable with STSymbol in some contexts.
 */
- (NSString *)string;

- (NSString *)prettyDescription;

@end

/*!
 @method
 @abstract	This category adds truthiness and pretty printing to NSNull.
 */
@interface NSNull (Stein)

+ (BOOL)isTrue;
- (BOOL)isTrue;

- (NSString *)prettyDescription;

@end

#pragma mark -

/*!
 @category
 @abstract	This category makes NSArray conform to the STEnumerable protocol.
 */
@interface NSArray (Stein) < STEnumerable >

@end

/*!
 @category
 @abstract	This category makes NSSet conform to the STEnumerable protocol.
 */
@interface NSSet (Stein) < STEnumerable >

@end

/*!
 @category
 @abstract	This category makes NSDictionary conform to the STEnumerable protocol.
 */
@interface NSDictionary (Stein) < STEnumerable >

@end
