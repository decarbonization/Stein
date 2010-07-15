//
//  STStructClasses.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STTypeBridge.h>

#pragma once

/*!
 @class
 @abstract	The STRange class is used to describe NSRange and CFRange structs in the Stein programming language.
 */
@interface STRange : NSObject <STPrimitiveValueWrapper>
{
	NSRange mRange;
}

#pragma mark Initialization

/*!
 @method
 @abstract	Initialize the receiver with a specified range value.
 */
- (id)initWithRange:(NSRange)range;

/*!
 @method
 @abstract	Initialize the receiver with a specified location, and a specified length.
 */
- (id)initWithLocation:(NSUInteger)location length:(NSUInteger)length;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The location of the range.
 */
@property NSUInteger location;

/*!
 @property
 @abstract	The length of the range.
 */
@property NSUInteger length;

#pragma mark -

/*!
 @property
 @abstract	The primitive value of the range.
 */
@property (readonly) NSRange rangeValue;

@end

/*!
 @const
 @abstract	The descriptor for the range struct wrapper.
 */
STPrimitiveValueWrapperDescriptor const kSTRangeStructWrapperDescriptor;

#pragma mark -

/*!
 @class
 @abstract	The STPoint class is used to describe NSPoint and CGPoint structs in the Stein programming language.
 */
@interface STPoint : NSObject <STPrimitiveValueWrapper>
{
	CGPoint mPoint;
}

#pragma mark Initialization

/*!
 @method
 @abstract	Initialize the receiver with a specified point value.
 */
- (id)initWithPoint:(CGPoint)point;

/*!
 @method
 @abstract	Initialize the receiver with a specified x offset, and a specified y offset.
 */
- (id)initWithX:(CGFloat)x y:(CGFloat)y;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The x offset of the point.
 */
@property CGFloat x;

/*!
 @property
 @abstract	The y offset of the point.
 */
@property CGFloat y;

#pragma mark -

/*!
 @property
 @abstract	The primitive value of the point.
 */
@property (readonly) CGPoint pointValue;

@end

/*!
 @const
 @abstract	The descriptor for the point struct wrapper.
 */
STPrimitiveValueWrapperDescriptor const kSTPointStructWrapperDescriptor;

#pragma mark -

/*!
 @class
 @abstract	The STSize class is used to describe NSSize and CGSize structs in the Stein programming language.
 */
@interface STSize : NSObject <STPrimitiveValueWrapper>
{
	CGSize mSize;
}

#pragma mark Initialization

/*!
 @method
 @abstract	Initialize the size with a specified size value.
 */
- (id)initWithSize:(CGSize)size;

/*!
 @method
 @abstract	Initialize the size with a specified with, and a specified height.
 */
- (id)initWithWidth:(CGFloat)width height:(CGFloat)height;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The width of the size.
 */
@property CGFloat width;

/*!
 @property
 @abstract	The height of the size.
 */
@property CGFloat height;

#pragma mark -

/*!
 @property
 @abstract	The primitive value of the size.
 */
@property (readonly) CGSize sizeValue;

@end

/*!
 @const
 @abstract	The descriptor for the size struct wrapper.
 */
STPrimitiveValueWrapperDescriptor const kSTSizeStructWrapperDescriptor;

#pragma mark -

/*!
 @class
 @abstract	The STRect class is used to describe NSRect and CGRect structs in the Stein programming language.
 */
@interface STRect : NSObject <STPrimitiveValueWrapper>
{
	STPoint *mOrigin;
	STSize *mSize;
}

#pragma mark Initialization

/*!
 @method
 @abstract	Initialize the receiver with a specified rect value.
 */
- (id)initWithRect:(CGRect)rect;

/*!
 @method
 @abstract	Initialize the receiver with a specified origin, and a specified size.
 */
- (id)initWithOrigin:(STPoint *)origin size:(STSize *)size;

/*!
 @method
 @abstract	Initialize the receiver with specified x and y coordinates, and width and height values.
 */
- (id)initWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The origin of the rect.
 */
@property (retain) STPoint *origin;

/*!
 @property
 @abstract	The size of the rect.
 */
@property (retain) STSize *size;

#pragma mark -

/*!
 @property
 @abstract	The primitive value of the rect.
 */
@property (readonly) CGRect rectValue;

@end

/*!
 @const
 @abstract	The descriptor for the rect struct wrapper.
 */
STPrimitiveValueWrapperDescriptor const kSTRectStructWrapperDescriptor;
