//
//  STPointer.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STEnumerable.h>

/*!
 @class
 @abstract	The STPointer class is used to represent pointers in the Stein programming language.
 */
@interface STPointer : NSObject < STEnumerable, NSCopying >
{
	/* n/a */	BOOL mIsArray;
	
	/* n/a */	size_t mLength;
	/* owner */	void *mBytes;
	/* owner */	char *mType;
}
#pragma mark Creation

/*!
 @method
 @abstract	Create a new autoreleased pointer of a specified type.
 @param		type	The type of the pointer to create. May not be NULL.
 @result	A new pointer object ready for use.
 */
+ (STPointer *)pointerWithType:(const char *)type;

/*!
 @method
 @abstract	Create a new autoreleased pointer whose contents will represent an array of values.
 @param		length	The number of values that will be placed in the pointers contents. Must be greater than 0.
 @param		type	The type of the values that will be stored in the pointer.
 @result	A new pointer object ready for use as an array.
 */
+ (STPointer *)arrayPointerOfLength:(NSUInteger)length type:(const char *)type;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract		The raw bytes of the pointer.
 @discussion	This property should never be accessed from within Stein. It is safe to write
				to the value returned by this property using the standard C library functions.
 */
@property (readonly) __strong void *bytes;

/*!
 @property
 @abstract	The type of the pointer's value.
 */
@property (readonly) __strong const char *type;

#pragma mark -

/*!
 @property
 @abstract	The length of the pointer in bytes.
 */
@property (readonly) size_t length;

/*!
 @property
 @abstract		The value of the pointer, as an object.
 @discussion	This property is unavailable for array pointers.
 */
@property (assign, nonatomic) id value;

#pragma mark -
#pragma mark Array Pointers

/*!
 @property
 @abstract		Sets the value located at `index`.
 @discussion	This method is unavailable for non-array pointers.
 */
- (void)setValue:(id)value atIndex:(NSUInteger)index;

/*!
 @property
 @abstract		Returns the value located at `index`.
 @discussion	This method is unavailable for non-array pointers.
 */
- (id)valueAtIndex:(NSUInteger)index;

#pragma mark -

/*!
 @property
 @abstract		The number of values within the pointer.
 @discussion	This property is unavailable for non-array pointers.
 */
@property (nonatomic) NSUInteger count;

@end
