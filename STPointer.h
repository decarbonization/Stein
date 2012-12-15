//
//  STPointer.h
//  stein
//
//  Created by Kevin MacWhinnie on 09/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stein/STEnumerable.h>

///The STPointer class is used to represent pointers in the Stein programming language.
@interface STPointer : NSObject < STEnumerable, NSCopying >
{
	BOOL mIsArray;
	
	size_t mLength;
	void *mBytes;
	char *mType;
}
#pragma mark Creation

///Create a new pointer of a specified type.
///
/// \param	type	The type of the pointer to create. May not be NULL.
///
/// \result	A new pointer object ready for use.
+ (STPointer *)pointerWithType:(const char *)type;

///Create a new pointer whose contents will represent an array of values.
///
/// \param	length	The number of values that will be placed in the pointers contents. Must be greater than 0.
/// \param	type	The type of the values that will be stored in the pointer.
///
/// \result	A new pointer object ready for use as an array.
+ (STPointer *)arrayPointerOfLength:(NSUInteger)length type:(const char *)type;

#pragma mark - Properties

///The raw bytes of the pointer.
///
///This property should never be accessed from within Stein. It is safe to write
///to the value returned by this property using the standard C library functions.
@property (readonly) void *bytes;

///The type of the pointer's value.
@property (readonly) const char *type;

#pragma mark -

///The length of the pointer in bytes.
@property (readonly) size_t length;

///The value of the pointer, as an object.
///
///This property is unavailable for array pointers.
@property (assign, nonatomic) id value;

#pragma mark - Array Pointers

///Sets the value located at `index`.
///
///This method is unavailable for non-array pointers.
- (void)setValue:(id)value atIndex:(NSUInteger)index;

///Returns the value located at `index`.
///
///This method is unavailable for non-array pointers.
- (id)valueAtIndex:(NSUInteger)index;

#pragma mark -

///The number of values within the pointer.
///
///This property is unavailable for non-array pointers.
@property (nonatomic) NSUInteger count;

@end
