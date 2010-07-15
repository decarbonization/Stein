//
//  NSObject+SteinTools.h
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
@interface NSObject (SteinTools)

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
#pragma mark Extension

/*!
 @method
 @abstract	Extend the receiver using a closure full of method constructs.
 */
+ (Class)extend:(STClosure *)extensions;

@end

#pragma mark -

/*!
 @abstract	This category adds pretty printing and overloaded math operators.
 */
@interface NSNumber (SteinTools)

- (NSString *)prettyDescription;

@end

/*!
 @abstract	This category provides overloaded math operators that operate on decimal numbers.
 */
@interface NSDecimalNumber (SteinTools)

@end

/*!
 @abstract	This category adds pretty printing and STEnumerable support to NSString.
 */
@interface NSString (SteinTools) <STEnumerable>

/*!
 @abstract		Returns the receiver.
 @discussion	This method exists to allow NSString to be interchangable with STSymbol in some contexts.
 */
- (NSString *)string;

- (NSString *)prettyDescription;

@end

/*!
 @abstract	This category adds pretty printing to NSNull.
 */
@interface NSNull (SteinTools)

- (NSString *)prettyDescription;

@end

#pragma mark -

/*!
 @abstract		This category makes NSArray conform to the STEnumerable protocol.
 @discussion	Stein extends NSArray so that any messages that it does not understand itself will
				be sent to all of its objects and the results will be collected into a new array.
 */
@interface NSArray (SteinTools) <STEnumerable>

#pragma mark Array Programming Support

/*!
 @abstract		Derive a new array by applying an array of boolean-like objects to the receivers contents.
 @param			booleans	An array of boolean-like objects the same length as the receiver. May not be nil.
 @result		A new array.
 @discussion	The `booleans` array should have a boolean-like object that corresponds to each object in
				the receiver. When a boolean-like object is found to be true, the corresponding object in
				the receiver will be placed into the new array.
 */
- (NSArray *)where:(NSArray *)booleans;

@end

/*!
 @abstract	This category makes NSSet conform to the STEnumerable protocol.
 */
@interface NSSet (SteinTools) <STEnumerable>

@end

/*!
 @abstract	This category makes NSIndexSet conform to the STEnumerable protocol.
 */
@interface NSIndexSet (SteinTools) <STEnumerable>

@end

/*!
 @abstract	This category makes NSDictionary conform to the STEnumerable protocol.
 */
@interface NSDictionary (SteinTools) <STEnumerable>

@end
