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

@interface STRange : NSObject < STPrimitiveValueWrapper >
{
	NSRange mRange;
}

- (id)initWithRange:(NSRange)range;
- (id)initWithLocation:(NSUInteger)location length:(NSUInteger)length;

@property NSUInteger location;
@property NSUInteger length;

@property (readonly) NSRange rangeValue;

@end
STPrimitiveValueWrapperDescriptor const kSTRangeStructWrapperDescriptor;

#pragma mark -

@interface STPoint : NSObject < STPrimitiveValueWrapper >
{
	CGPoint mPoint;
}

- (id)initWithPoint:(CGPoint)point;
- (id)initWithX:(CGFloat)x y:(CGFloat)y;

@property CGFloat x;
@property CGFloat y;

@property (readonly) CGPoint pointValue;

@end
STPrimitiveValueWrapperDescriptor const kSTPointStructWrapperDescriptor;

#pragma mark -

@interface STSize : NSObject < STPrimitiveValueWrapper >
{
	CGSize mSize;
}

- (id)initWithSize:(CGSize)size;
- (id)initWithWidth:(CGFloat)width height:(CGFloat)height;

@property CGFloat width;
@property CGFloat height;

@property (readonly) CGSize sizeValue;

@end
STPrimitiveValueWrapperDescriptor const kSTSizeStructWrapperDescriptor;

@interface STRect : NSObject < STPrimitiveValueWrapper >
{
	STPoint *mOrigin;
	STSize *mSize;
}

- (id)initWithRect:(CGRect)rect;
- (id)initWithOrigin:(STPoint *)origin size:(STSize *)size;
- (id)initWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;

@property (retain) STPoint *origin;
@property (retain) STSize *size;

@property (readonly) CGRect rectValue;

@end
STPrimitiveValueWrapperDescriptor const kSTRectStructWrapperDescriptor;
