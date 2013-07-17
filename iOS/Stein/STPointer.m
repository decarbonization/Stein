//
//  STPointer.m
//  stein
//
//  Created by Kevin MacWhinnie on 09/12/23.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STPointer.h"
#import "STTypeBridge.h"
#import "NSObject+SteinTools.h"
#import "STList.h"

@implementation STPointer

- (void)dealloc
{
    free(mType);
    mType = NULL;
    
    free(mBytes);
    mBytes = NULL;
}

#pragma mark Initialization

///Initialize the receiver with a specified size and a specified type.
///
/// \param		size	The size of the pointer's buffer. Must be greater than 0.
/// \param		type	The type of the value that will be stored in the pointer's buffer. May not be NULL.
///
/// \result		A fully initialized pointer with a buffer to hold the value described.
///
///You do not generally use this initializer to create a pointer object. Rather, it is
///recommended that you use `pointerWithType:` or `arrayPointerOfLength:type:` to create
///your pointer objects.
- (id)initWithSize:(size_t)size type:(const char *)type isArray:(BOOL)isArray
{
	NSAssert((size > 0), @"Size is 0. You cannot create an empty pointer.");
	NSParameterAssert(type);
	
	if((self = [super init]))
	{
		mType = malloc(strlen(type) + 1);
		NSAssert((mType != NULL), @"Could not allocate type buffer for pointer of type %s.", type);
		
		strcpy(mType, type);
		
		
		mBytes = malloc(size);
		NSAssert((mBytes != NULL), @"Could not allocate pointer storage of size %zd.", size);
		
		bzero(mBytes, size);
		
		
		mLength = size;
		
		mIsArray = isArray;
		
		return self;
	}
	return nil;
}

///Initialize the receiver as a pointer suitable to hold a single object.
- (id)init
{
	return [self initWithSize:sizeof(id) type:@encode(id) isArray:NO];
}

#pragma mark - Creation

+ (STPointer *)pointerWithType:(const char *)type
{
    NSUInteger size = 0;
    NSGetSizeAndAlignment(type, &size, NULL);
	return [[self alloc] initWithSize:size type:type isArray:NO];
}

+ (STPointer *)arrayPointerOfLength:(NSUInteger)length type:(const char *)type
{
	NSAssert((length > 0), @"Length is 0. You cannot create an empty pointer array.");
	NSParameterAssert(type);
	
    NSUInteger sizeOfType = 0;
    NSGetSizeAndAlignment(type, &sizeOfType, NULL);
	return [[self alloc] initWithSize:(sizeOfType * length) type:type isArray:YES];
}

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone
{
	STPointer *pointer = [[STPointer allocWithZone:zone] initWithSize:mLength type:mType isArray:mIsArray];
	memcpy(pointer.bytes, mBytes, mLength);
	
	return pointer;
}

#pragma mark - Identity

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[STPointer class]])
	{
		return ([self length] == [object length] && [self bytes] == [object bytes]);
	}
	
	return [self.value isEqual:object];
}

- (NSString *)description
{
	if(mIsArray)
		return [NSString stringWithFormat:@"<%@:%p %s[%d]>", [self className], self, mType, self.count];
	
	return [NSString stringWithFormat:@"<%@:%p %s>", [self className], self, mType];
}

- (NSString *)prettyDescription
{
	if(mIsArray)
	{
		NSMutableString *description = [NSMutableString stringWithString:@"ref {\n"];
		
		NSUInteger pointerCount = self.count;
		for (NSUInteger index = 0; index < pointerCount; index++)
		{
			[description appendFormat:@"\t%@,\n", [[self valueAtIndex:index] prettyDescription]];
		}
		
		[description appendString:@"}"];
		
		return description;
	}
	
	return [NSString stringWithFormat:@"ref %@", [self.value prettyDescription]];
}

#pragma mark - Properties

@synthesize bytes = mBytes;
@synthesize type = mType;

#pragma mark -

@synthesize length = mLength;

- (void)setValue:(id)value
{
	NSAssert(!mIsArray, @"You cannot mutate the contents of a pointer array through the value property.");
	
	NSParameterAssert(value);
	
	STTypeBridgeConvertObjectIntoType(value, mType, (void **)mBytes);
}

- (id)value
{
	NSAssert(!mIsArray, @"You cannot access the contents of a pointer array through the value property.");
	
	return STTypeBridgeConvertValueOfTypeIntoObject(mBytes, mType);
}

#pragma mark - Array Pointers

- (void)setCount:(NSUInteger)count
{
	NSAssert(mIsArray, @"count is not available for non-array pointers.");
	
    NSUInteger size = 0;
    NSGetSizeAndAlignment(mType, &size, NULL);
	NSAssert(realloc(mBytes, (size * count)),
			 @"Could not resize pointer of type %s to count %d.", mType, count);
}

- (NSUInteger)count
{
	NSAssert(mIsArray, @"count is not available for non-array pointers.");
	
    NSUInteger size = 0;
    NSGetSizeAndAlignment(mType, &size, NULL);
	return (mLength / size);
}

#pragma mark -

- (void)setValue:(id)value atIndex:(NSUInteger)index
{
	NSAssert(mIsArray, @"You cannot mutate the contents of a non-pointer array through setValue:atIndex:");
	
	NSParameterAssert(value);
	NSAssert((index < self.count), @"Index %d is beyond pointer bounds %d.", index, self.count);
	
    NSUInteger size = 0;
    NSGetSizeAndAlignment(mType, &size, NULL);
	Byte *destination = (((Byte *)mBytes) + (size * index));
	STTypeBridgeConvertObjectIntoType(value, mType, (void **)destination);
}

- (id)valueAtIndex:(NSUInteger)index
{
	NSAssert(mIsArray, @"You cannot access the contents of a non-pointer array through valueAtIndex:");
	
	NSAssert((index < self.count), @"Index %d is beyond pointer bounds %d.", index, self.count);
	
    NSUInteger size = 0;
    NSGetSizeAndAlignment(mType, &size, NULL);
	Byte *primitiveValue = (((Byte *)mBytes) + (size * index));
	return STTypeBridgeConvertValueOfTypeIntoObject(primitiveValue, mType);
}

#pragma mark - STEnumerable

- (id)foreach:(id <STFunction>)function
{
	NSAssert(mIsArray, @"You cannot enumerate a non-array pointer.");
	
	NSUInteger valueCount = self.count;
	for (NSUInteger index = 0; index < valueCount; index++)
	{
		STFunctionApply(function, [[STList alloc] initWithObject:[self valueAtIndex:index]]);
	}
	
	return self;
}

- (id)map:(id <STFunction>)function
{
	NSAssert(mIsArray, @"You cannot map a non-array pointer.");
	
	STPointer *mappedPointerArray = [STPointer arrayPointerOfLength:self.count type:mType];
	
	NSUInteger valueCount = self.count;
	for (NSUInteger index = 0; index < valueCount; index++)
	{
		id mappedValue = STFunctionApply(function, [[STList alloc] initWithObject:[self valueAtIndex:index]]);
		[mappedPointerArray setValue:mappedValue atIndex:index];
	}
	
	return mappedPointerArray;
}

- (id)filter:(id <STFunction>)function
{
	NSAssert(mIsArray, @"You cannot filter a non-array pointer.");
	
	STPointer *filteredPointerArray = [STPointer arrayPointerOfLength:1 type:mType];
	
	NSUInteger valueCount = self.count;
	for (NSUInteger index = 0; index < valueCount; index++)
	{
		id value = [filteredPointerArray valueAtIndex:index];
		if(STIsTrue(STFunctionApply(function, [[STList alloc] initWithObject:value])))
		{
			filteredPointerArray.count++;
			[filteredPointerArray setValue:value atIndex:filteredPointerArray.count - 1];
		}
	}
	
	return filteredPointerArray;
}

@end
