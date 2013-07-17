//
//  STStructClasses.h
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTypeBridge.h"

#ifndef STStructClasses_h
#define STStructClasses_h 1

///The STRange class is used to describe NSRange and CFRange structs in the Stein programming language.
@interface STRange : NSObject <STPrimitiveValueWrapper>
{
	NSRange mRange;
}

#pragma mark Initialization

///Initialize the receiver with a specified range value.
- (id)initWithRange:(NSRange)range;

///Initialize the receiver with a specified location, and a specified length.
- (id)initWithLocation:(NSUInteger)location length:(NSUInteger)length;

#pragma mark - Properties

///The location of the range.
@property NSUInteger location;

///The length of the range.
@property NSUInteger length;

#pragma mark -

///The primitive value of the range.
@property (readonly) NSRange rangeValue;

@end

///The descriptor for the range struct wrapper.
STPrimitiveValueWrapperDescriptor const kSTRangeStructWrapperDescriptor;

#pragma mark -

///The STPoint class is used to describe NSPoint and CGPoint structs in the Stein programming language.
@interface STPoint : NSObject <STPrimitiveValueWrapper>
{
	CGPoint mPoint;
}

#pragma mark Initialization

///Initialize the receiver with a specified point value.
- (id)initWithPoint:(CGPoint)point;

///Initialize the receiver with a specified x offset, and a specified y offset.
- (id)initWithX:(CGFloat)x y:(CGFloat)y;

#pragma mark - Properties

///The x offset of the point.
@property CGFloat x;

///The y offset of the point.
@property CGFloat y;

#pragma mark -

///The primitive value of the point.
@property (readonly) CGPoint pointValue;

@end

///The descriptor for the point struct wrapper.
STPrimitiveValueWrapperDescriptor const kSTPointStructWrapperDescriptor;

#pragma mark -

///The STSize class is used to describe NSSize and CGSize structs in the Stein programming language.
@interface STSize : NSObject <STPrimitiveValueWrapper>
{
	CGSize mSize;
}

#pragma mark Initialization

///Initialize the size with a specified size value.
- (id)initWithSize:(CGSize)size;

///Initialize the size with a specified with, and a specified height.
- (id)initWithWidth:(CGFloat)width height:(CGFloat)height;

#pragma mark - Properties

///The width of the size.
@property CGFloat width;

///The height of the size.
@property CGFloat height;

#pragma mark -

///The primitive value of the size.
@property (readonly) CGSize sizeValue;

@end

///The descriptor for the size struct wrapper.
STPrimitiveValueWrapperDescriptor const kSTSizeStructWrapperDescriptor;

#pragma mark -

///The STRect class is used to describe CGRect structs in the Stein programming language.
@interface STRect : NSObject <STPrimitiveValueWrapper>
{
	STPoint *mOrigin;
	STSize *mSize;
}

#pragma mark Initialization

///Initialize the receiver with a specified rect value.
- (id)initWithRect:(CGRect)rect;

///Initialize the receiver with a specified origin, and a specified size.
- (id)initWithOrigin:(STPoint *)origin size:(STSize *)size;

///Initialize the receiver with specified x and y coordinates, and width and height values.
- (id)initWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;

#pragma mark - Properties

///The origin of the rect.
@property (retain) STPoint *origin;

///The size of the rect.
@property (retain) STSize *size;

#pragma mark -

///The primitive value of the rect.
@property (readonly) CGRect rectValue;

@end

///The descriptor for the rect struct wrapper.
STPrimitiveValueWrapperDescriptor const kSTRectStructWrapperDescriptor;

#endif /* STStructClasses_h */
