//
//  STStructClasses.m
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STStructClasses.h"
#import "STFunction.h"
#import "STEnumerable.h"
#import "STList.h"

static BOOL _CStringHasPrefix(const char *string, const char *prefix)
{
	if(strlen(prefix) > strlen(string))
		return NO;
	
	int prefixLength = strlen(prefix);
	for (int index = 0; index < prefixLength; index++)
	{
		if(string[index] != prefix[index])
		{
			return NO;
		}
	}
	
	return YES;
}

#pragma mark -

@implementation STRange

+ (void)load
{
	STTypeBridgeRegisterWrapper(@"Range", &kSTRangeStructWrapperDescriptor);
}

#pragma mark - Initialization

- (id)initWithRange:(NSRange)range
{
	return [self initWithLocation:range.location length:range.length];
}

- (id)initWithLocation:(NSUInteger)location length:(NSUInteger)length
{
	if((self = [super init]))
	{
		mRange.location = location;
		mRange.length = length;
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

- (void)setLocation:(NSUInteger)location
{
	@synchronized(self)
	{
		mRange.location = location;
	}
}

- (NSUInteger)location
{
	@synchronized(self)
	{
		return mRange.location;
	}
}

#pragma mark -

- (void)setLength:(NSUInteger)length
{
	@synchronized(self)
	{
		mRange.length = length;
	}
}

- (NSUInteger)length
{
	@synchronized(self)
	{
		return mRange.length;
	}
}

#pragma mark -

- (NSRange)rangeValue
{
	@synchronized(self)
	{
		return mRange;
	}
}

#pragma mark - Implementing <STEnumerable>

- (id)foreach:(id <STFunction>)function
{
	for (NSUInteger index = 0, count = mRange.location + mRange.length; index < count; index++)
	{
		NSNumber *number = [NSNumber numberWithUnsignedInteger:index];
		@try
		{
			STFunctionApply(function, [[STList alloc] initWithObject:number]);
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return self;
}

#pragma mark - Bridging

- (void)getValue:(void **)buffer forType:(const char *)objcType
{
	*(NSRange *)buffer = mRange;
}

- (const STPrimitiveValueWrapperDescriptor *)descriptor
{
	return &kSTPointStructWrapperDescriptor;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p { %ld, %ld }>", [self className], self, mRange.location, mRange.length];
}

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"range %ld %ld", mRange.location, mRange.length];
}

@end

#pragma mark -

static BOOL STRangeCanWrapValueWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	if(sizeof(NSRange) == sizeof(CFRange))
		return _CStringHasPrefix(objcType, "{_NSRange=") || _CStringHasPrefix(objcType, "{CFRange=");
	   
	   return _CStringHasPrefix(objcType, "{_NSRange=");
}

static id < STPrimitiveValueWrapper > STRangeWrapDataWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, void *data, const char *objcType)
{
	return [[STRange alloc] initWithRange:*(NSRange *)data];
}

static size_t STRangeSizeOfPrimitiveValue(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return sizeof(NSRange);
}

static const char *STRangeObjCType(const STPrimitiveValueWrapperDescriptor *descriptor)
{
	return @encode(NSRange);
}

STPrimitiveValueWrapperDescriptor const kSTRangeStructWrapperDescriptor = {
	.userData = NULL,
	.CanWrapValueWithSignature = STRangeCanWrapValueWithSignature,
	.WrapDataWithSignature = STRangeWrapDataWithSignature,
	.SizeOfPrimitiveValue = STRangeSizeOfPrimitiveValue,
	.ObjCType = STRangeObjCType,
};

#pragma mark -

@implementation STPoint

+ (void)load
{
	STTypeBridgeRegisterWrapper(@"Point", &kSTPointStructWrapperDescriptor);
}

#pragma mark - Initialization

- (id)initWithPoint:(CGPoint)point
{
	return [self initWithX:point.x y:point.y];
}

- (id)initWithX:(CGFloat)x y:(CGFloat)y
{
	if((self = [super init]))
	{
		mPoint.x = x;
		mPoint.y = y;
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

- (void)setX:(CGFloat)x
{
	@synchronized(self)
	{
		mPoint.x = x;
	}
}

- (CGFloat)x
{
	@synchronized(self)
	{
		return mPoint.x;
	}
}

#pragma mark -

- (void)setY:(CGFloat)y
{
	@synchronized(self)
	{
		mPoint.y = y;
	}
}

- (CGFloat)y
{
	@synchronized(self)
	{
		return mPoint.y;
	}
}

#pragma mark -

- (CGPoint)pointValue
{
	@synchronized(self)
	{
		return mPoint;
	}
}

#pragma mark - Bridging

- (void)getValue:(void **)buffer forType:(const char *)objcType
{
	*(CGPoint *)buffer = mPoint;
}

- (const STPrimitiveValueWrapperDescriptor *)descriptor
{
	return &kSTPointStructWrapperDescriptor;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p { %f, %f }>", [self className], self, mPoint.x, mPoint.y];
}

@end

#pragma mark -

static BOOL STPointCanWrapValueWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return _CStringHasPrefix(objcType, "{CGPoint=") || _CStringHasPrefix(objcType, "{_NSPoint=");
}

static id < STPrimitiveValueWrapper > STPointWrapDataWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, void *data, const char *objcType)
{
	return [[STPoint alloc] initWithPoint:*(CGPoint *)data];
}

static size_t STPointSizeOfPrimitiveValue(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return sizeof(CGPoint);
}

static const char *STPointObjCType(const STPrimitiveValueWrapperDescriptor *descriptor)
{
	return @encode(NSPoint);
}

STPrimitiveValueWrapperDescriptor const kSTPointStructWrapperDescriptor = {
	.userData = NULL,
	.CanWrapValueWithSignature = STPointCanWrapValueWithSignature,
	.WrapDataWithSignature = STPointWrapDataWithSignature,
	.SizeOfPrimitiveValue = STPointSizeOfPrimitiveValue,
	.ObjCType = STPointObjCType,
};

#pragma mark -

@implementation STSize

+ (void)load
{
	STTypeBridgeRegisterWrapper(@"Size", &kSTSizeStructWrapperDescriptor);
}

#pragma mark - Initialization

- (id)initWithSize:(CGSize)size
{
	return [self initWithWidth:size.width height:size.height];
}

- (id)initWithWidth:(CGFloat)width height:(CGFloat)height
{
	if((self = [super init]))
	{
		mSize.width = width;
		mSize.height = height;
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

- (void)setWidth:(CGFloat)width
{
	@synchronized(self)
	{
		mSize.width = width;
	}
}

- (CGFloat)width
{
	@synchronized(self)
	{
		return mSize.width;
	}
}

#pragma mark -

- (void)setHeight:(CGFloat)height
{
	@synchronized(self)
	{
		mSize.height = height;
	}
}

- (CGFloat)height
{
	@synchronized(self)
	{
		return mSize.height;
	}
}

#pragma mark -

- (CGSize)sizeValue
{
	@synchronized(self)
	{
		return mSize;
	}
}

#pragma mark - Bridging

- (void)getValue:(void **)buffer forType:(const char *)objcType
{
	*(CGSize *)buffer = mSize;
}

- (const STPrimitiveValueWrapperDescriptor *)descriptor
{
	return &kSTSizeStructWrapperDescriptor;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p { %f, %f }>", [self className], self, mSize.width, mSize.height];
}

@end

#pragma mark -

static BOOL STSizeCanWrapValueWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return _CStringHasPrefix(objcType, "{CGSize=") || _CStringHasPrefix(objcType, "{_NSSize=");
}

static id < STPrimitiveValueWrapper > STSizeWrapDataWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, void *data, const char *objcType)
{
	return [[STSize alloc] initWithSize:*(NSSize *)data];
}

static size_t STSizeSizeOfPrimitiveValue(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return sizeof(NSSize);
}

static const char *STSizeObjCType(const STPrimitiveValueWrapperDescriptor *descriptor)
{
	return @encode(NSSize);
}

STPrimitiveValueWrapperDescriptor const kSTSizeStructWrapperDescriptor = {
	.userData = NULL,
	.CanWrapValueWithSignature = STSizeCanWrapValueWithSignature,
	.WrapDataWithSignature = STSizeWrapDataWithSignature,
	.SizeOfPrimitiveValue = STSizeSizeOfPrimitiveValue,
	.ObjCType = STSizeObjCType,
};

#pragma mark -

@implementation STRect

+ (void)load
{
	STTypeBridgeRegisterWrapper(@"Rect", &kSTRectStructWrapperDescriptor);
}

#pragma mark - Initialization

- (id)initWithRect:(CGRect)rect
{
	return [self initWithX:CGRectGetMinX(rect) 
						 y:CGRectGetMinY(rect) 
					 width:CGRectGetWidth(rect) 
					height:CGRectGetHeight(rect)];
}

- (id)initWithOrigin:(STPoint *)origin size:(STSize *)size
{
	if((self = [super init]))
	{
		mOrigin = origin ?: [STPoint new];
		mSize = size ?: [STSize new];
		
		return self;
	}
	return nil;
}

- (id)initWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height
{
	STPoint *origin = [[STPoint alloc] initWithX:x y:y];
	STSize *size = [[STSize alloc] initWithWidth:width height:height];
	return [self initWithOrigin:origin size:size];
}

#pragma mark - Size

@synthesize origin = mOrigin;
@synthesize size = mSize;

#pragma mark -

- (CGRect)rectValue
{
	return (CGRect){ .origin = mOrigin.pointValue, .size = mSize.sizeValue };
}

#pragma mark - Bridging

- (void)getValue:(void **)buffer forType:(const char *)objcType
{
	*(CGRect *)buffer = self.rectValue;
}

- (const STPrimitiveValueWrapperDescriptor *)descriptor
{
	return &kSTRectStructWrapperDescriptor;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p { %@, %@ }>", [self className], self, mOrigin, mSize];
}

@end

#pragma mark -

static BOOL STRectCanWrapValueWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return _CStringHasPrefix(objcType, "{CGRect=") || _CStringHasPrefix(objcType, "{_NSRect=");
}

static id < STPrimitiveValueWrapper > STRectWrapDataWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, void *data, const char *objcType)
{
	return [[STRect alloc] initWithRect:*(CGRect *)data];
}

static size_t STRectSizeOfPrimitiveValue(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return sizeof(CGRect);
}

static const char *STRectObjCType(const STPrimitiveValueWrapperDescriptor *descriptor)
{
	return @encode(NSRect);
}

STPrimitiveValueWrapperDescriptor const kSTRectStructWrapperDescriptor = {
	.userData = NULL,
	.CanWrapValueWithSignature = STRectCanWrapValueWithSignature,
	.WrapDataWithSignature = STRectWrapDataWithSignature,
	.SizeOfPrimitiveValue = STRectSizeOfPrimitiveValue,
	.ObjCType = STRectObjCType,
};
