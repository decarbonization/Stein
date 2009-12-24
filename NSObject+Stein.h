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
@class STClosure;

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
+ (Class)extend:(STClosure *)extensions;

@end

#pragma mark -

/*!
 @method
 @abstract	This category adds truthiness and pretty printing to NSNumber.
 */
@interface NSNumber (Stein)

- (BOOL)isTrue;
- (NSString *)prettyDescription;

@end

/*!
 @method
 @abstract	Pretty printing to NSString.
 */
@interface NSString (Stein)

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
