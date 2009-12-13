//
//  STStructClasses.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STTypeBridge.h>

#pragma once

@interface STRange : NSObject < StructWrapper >
{
	NSRange mRange;
}

- (id)initWithRange:(NSRange)range;
- (id)initWithLocation:(NSUInteger)location length:(NSUInteger)length;

@property NSUInteger location;
@property NSUInteger length;

@property (readonly) NSRange rangeValue;

@end
StructWrapperDescriptor const kSTRangeStructWrapperDescriptor;

#pragma mark -

@interface STPoint : NSObject < StructWrapper >
{
	CGPoint mPoint;
}

- (id)initWithPoint:(CGPoint)point;
- (id)initWithX:(CGFloat)x y:(CGFloat)y;

@property CGFloat x;
@property CGFloat y;

@property (readonly) CGPoint pointValue;

@end
StructWrapperDescriptor const kSTPointStructWrapperDescriptor;

#pragma mark -

@interface STSize : NSObject < StructWrapper >
{
	CGSize mSize;
}

- (id)initWithSize:(CGSize)size;
- (id)initWithWidth:(CGFloat)width height:(CGFloat)height;

@property CGFloat width;
@property CGFloat height;

@property (readonly) CGSize sizeValue;

@end
StructWrapperDescriptor const kSTSizeStructWrapperDescriptor;

@interface STRect : NSObject < StructWrapper >
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
StructWrapperDescriptor const kSTRectStructWrapperDescriptor;
