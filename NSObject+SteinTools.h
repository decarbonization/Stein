//
//  NSObject+SteinTools.h
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stein/STEnumerable.h>

@protocol STFunction;
@class STClosure;

///This category adds several collections of methods to NSObject that are used extensively by Stein.
///These methods include decision making control flow constructs (ifTrue/match), class extension, and printing.
@interface NSObject (SteinTools)

#pragma mark Printing

///Returns a string that represents the contents of the receiving object that is easily readable in the context of a command prompt.
- (NSString *)prettyDescription;

///Print the receiver, using it's pretty description.
- (NSString *)prettyPrint;

#pragma mark -

///Print the receiver.
- (NSString *)print;

#pragma mark - Extension

///Extend the receiver using a closure full of method constructs.
+ (Class)extend:(STClosure *)extensions;

@end

#pragma mark -

///This category adds pretty printing and overloaded math operators.
@interface NSNumber (SteinTools)

- (NSString *)prettyDescription;

@end

///This category provides overloaded math operators that operate on decimal numbers.
@interface NSDecimalNumber (SteinTools)

@end

///This category adds pretty printing and STEnumerable support to NSString.
@interface NSString (SteinTools) <STEnumerable>

///Returns the receiver.
///
///This method exists to allow NSString to be interchangable with STSymbol in some contexts.
- (NSString *)string;

- (NSString *)prettyDescription;

@end

///This category adds pretty printing to NSNull.
@interface NSNull (SteinTools)

- (NSString *)prettyDescription;

@end

#pragma mark -

///This category makes NSArray conform to the STEnumerable protocol.
///Stein extends NSArray so that any messages that it does not understand itself will
///be sent to all of its objects and the results will be collected into a new array.
@interface NSArray (SteinTools) <STEnumerable>

#pragma mark Array Programming Support

///Derive a new array by applying an array of boolean-like objects to the receivers contents.
/// \param		booleans	An array of boolean-like objects the same length as the receiver. May not be nil.
/// \result		A new array.
///The `booleans` array should have a boolean-like object that corresponds to each object in
///the receiver. When a boolean-like object is found to be true, the corresponding object in
///the receiver will be placed into the new array.
- (NSArray *)where:(NSArray *)booleans;

@end

///This category makes NSSet conform to the STEnumerable protocol.
@interface NSSet (SteinTools) <STEnumerable>

@end

///This category makes NSIndexSet conform to the STEnumerable protocol.
@interface NSIndexSet (SteinTools) <STEnumerable>

@end

///This category makes NSDictionary conform to the STEnumerable protocol.
@interface NSDictionary (SteinTools) <STEnumerable>

@end
