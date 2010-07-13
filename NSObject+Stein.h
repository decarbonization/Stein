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
 @protocol
 @abstract		The STMethodMissing protocol defines methods used by the high level 
				forwarding mechanism implemented in Stein's object bridge.
 @discussion	The Stein object bridge's forwarding mechanism is considerably higher level than
				the forwarding mechanism provided by the Objective-C runtime. All values are passed
				around as objects, type information is unnecessary. This allows a considerably cleaner
				method of responding to unknown messages in an abstract manner.
 
				This forwarding mechanism is used to implement infix arithmetic on NSNumber.
 */
@protocol STMethodMissing

/*!
 @method
 @abstract		Returns whether or not the receiver can handle a missing method with a specified selector.
 @param			selector	The method which contains no known implementation in the receiver.
 @param			scope		The scope in which the receiver was called from.
 @result		YES if the receiver can handle the selector; NO otherwise.
 @discussion	This method is invoked by the Stein runtime when an object doesn't respond to a specified selector.
 */
- (BOOL)canHandleMissingMethodWithSelector:(SEL)selector;

/*!
 @method
 @abstract		Perform an action for a missing method.
 @param			selector	The method to perform an action for.
 @param			arguments	The arguments passed to the method.
 @param			scope		The scope in which the receiver was called from.
 @result		The result of the action performed.
 @discussion	This method is only called if -[STMethodMissing canHandleMissingMethodWithSelector:inScope:] returns YES.
				
				NSObject's default implementation of this method logs an error message and returns STNull.
 */
- (id)handleMissingMethodWithSelector:(SEL)selector arguments:(NSArray *)arguments inScope:(STScope *)scope;

@end

/*!
 @category
 @abstract	This category adds several collections of methods to NSObject that are used extensively by Stein.
			These methods include decision making control flow constructs (ifTrue/match), class extension,
			and printing.
 */
@interface NSObject (Stein) < STMethodMissing >

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
 @abstract	This category adds pretty printing and infix notation support to NSNumber.
 */
@interface NSNumber (Stein) < STMethodMissing >

- (NSString *)prettyDescription;

@end

/*!
 @abstract	This category adds pretty printing and STEnumerable support to NSString.
 */
@interface NSString (Stein) < STEnumerable >

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
@interface NSNull (Stein)

- (NSString *)prettyDescription;

@end

#pragma mark -

/*!
 @abstract		This category makes NSArray conform to the STEnumerable protocol.
 @discussion	Stein extends NSArray so that any messages that it does not understand itself will
				be sent to all of its objects and the results will be collected into a new array.
 */
@interface NSArray (Stein) < STEnumerable >

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
@interface NSSet (Stein) < STEnumerable >

@end

/*!
 @abstract	This category makes NSDictionary conform to the STEnumerable protocol.
 */
@interface NSDictionary (Stein) < STEnumerable >

@end
