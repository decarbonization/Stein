//
//  STTypeBridge.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STTypeBridge.h"
#import <objc/objc.h>
#import <libkern/OSAtomic.h>
#import <ffi/ffi.h>

#import "STPointer.h"

#pragma mark Tools

//The below enumerations are provided to improve code readability, and to potentially
//allow support for other Objective-C runtimes with unique type signature patterns. 
enum ObjectiveCTypeModifier {
	kObjectiveCTypeModifierConst = 'r',
	kObjectiveCTypeModifierIn = 'n',
	kObjectiveCTypeModifierInout = 'N',
	kObjectiveCTypeModifierOut = 'o',
	kObjectiveCTypeModifierBycopy = 'O',
	kObjectiveCTypeModifierByref = 'R',
	kObjectiveCTypeModifierOneway = 'V',
};

enum ObjectiveCType {
	kObjectiveCTypeChar = 'c',
	kObjectiveCTypeInt = 'i',
	kObjectiveCTypeShort = 's',
	kObjectiveCTypeLong = 'l',
	kObjectiveCTypeLongLong = 'q',
	kObjectiveCTypeUnsignedChar = 'C',
	kObjectiveCTypeUnsignedInt = 'I',
	kObjectiveCTypeUnsignedShort = 'S',
	kObjectiveCTypeUnsignedLong = 'L',
	kObjectiveCTypeUnsignedLongLong = 'Q',
	kObjectiveCTypeFloat = 'f',
	kObjectiveCTypeDouble = 'd',
	kObjectiveCTypeBool = 'B',
	kObjectiveCTypeVoid = 'v',
	kObjectiveCTypeCString = '*',
	kObjectiveCTypePointer = '^',
	kObjectiveCTypeClass = '#',
	kObjectiveCTypeObject = '@',
	kObjectiveCTypeSelector = ':',
	kObjectiveCTypeStruct = '{',
	kObjectiveCTypeCArray = '[',
	kObjectiveCTypeUnion = '(',
	kObjectiveCTypeBitfield = 'b',
	kObjectiveCTypeUnknown = '?',
};

static ffi_type *STTypeBridgeGetFFITypeForStruct(const char *objcType);
ffi_type *STTypeBridgeConvertObjCTypeToFFIType(const char *objcType);

#pragma mark -

/*!
 @function
 @abstract		Return the relevant type for a specified Objective-C type string
 @param			objcType	May not be NULL.
 @discussion	Objective-C type strings can contain remote-messaging modifiers. We don't care
				about those. This function simply returns a string without those modifiers.
 */
static const char *GetRelevantTypeForObjCType(const char *objcType)
{
	NSCParameterAssert(objcType);
	
	char firstCharacterOfType = objcType[0];
	if(firstCharacterOfType == kObjectiveCTypeModifierConst || firstCharacterOfType == kObjectiveCTypeModifierIn ||
	   firstCharacterOfType == kObjectiveCTypeModifierInout || firstCharacterOfType == kObjectiveCTypeModifierOut ||
	   firstCharacterOfType == kObjectiveCTypeModifierBycopy || firstCharacterOfType == kObjectiveCTypeModifierByref ||
	   firstCharacterOfType == kObjectiveCTypeModifierOneway)
	{
		return objcType + 1;
	}
	
	return objcType;
}

#pragma mark -
#pragma mark Size look up

size_t STTypeBridgeGetSizeOfObjCType(const char *objcType)
{
	const char *type = GetRelevantTypeForObjCType(objcType);
	
	switch (type[0])
	{
		case kObjectiveCTypeChar:
			return sizeof(char);
			
		case kObjectiveCTypeInt:
			return sizeof(int);
			
		case kObjectiveCTypeShort:
			return sizeof(short);
			
		case kObjectiveCTypeLong:
			return sizeof(long);
			
		case kObjectiveCTypeLongLong:
			return sizeof(long long);
			
		case kObjectiveCTypeUnsignedChar:
			return sizeof(unsigned char);
			
		case kObjectiveCTypeUnsignedInt:
			return sizeof(unsigned int);
			
		case kObjectiveCTypeUnsignedShort:
			return sizeof(unsigned short);
			
		case kObjectiveCTypeUnsignedLong:
			return sizeof(unsigned long);
			
		case kObjectiveCTypeUnsignedLongLong:
			return sizeof(unsigned long long);
			
		case kObjectiveCTypeFloat:
			return sizeof(float);
			
		case kObjectiveCTypeDouble:
			return sizeof(double);
			
		case kObjectiveCTypeBool:
			return sizeof(_Bool);
			
		case kObjectiveCTypeVoid:
			return sizeof(void);
			
		case kObjectiveCTypeCString:
			return sizeof(const char *);
			
		case kObjectiveCTypePointer:
			return sizeof(void *);
			
		case kObjectiveCTypeClass:
			return sizeof(Class);
			
		case kObjectiveCTypeObject:
			return sizeof(id);
			
		case kObjectiveCTypeSelector:
			return sizeof(SEL);
			
		case kObjectiveCTypeStruct: {
			const STPrimitiveValueWrapperDescriptor *wrapperDescriptor = STTypeBridgeGetWrapperForType(type);
			return wrapperDescriptor->SizeOfPrimitiveValue(wrapperDescriptor, type);
		}
			
		case kObjectiveCTypeCArray:
		case kObjectiveCTypeUnion:
		case kObjectiveCTypeBitfield:
		case kObjectiveCTypeUnknown:
			NSCAssert(0, @"Type %s cannot be handled by the stein type bridge.", objcType);
			
		default:
			break;
	}
	
	return 0;
}

#pragma mark -
#pragma mark Converting Values to and from Objects

id STTypeBridgeConvertValueOfTypeIntoObject(void *value, const char *objcType)
{
	const char *type = GetRelevantTypeForObjCType(objcType);
	
	switch (type[0])
	{
		case kObjectiveCTypeChar:
			return [NSNumber numberWithChar:*(char *)value];
			
		case kObjectiveCTypeInt:
			return [NSNumber numberWithInt:*(int *)value];
			
		case kObjectiveCTypeShort:
			return [NSNumber numberWithShort:*(short *)value];
			
		case kObjectiveCTypeLong:
			return [NSNumber numberWithLong:*(long *)value];
			
		case kObjectiveCTypeLongLong:
			return [NSNumber numberWithLongLong:*(long long *)value];
			
		case kObjectiveCTypeUnsignedChar:
			return [NSNumber numberWithUnsignedChar:*(unsigned char *)value];
			
		case kObjectiveCTypeUnsignedInt:
			return [NSNumber numberWithUnsignedInt:*(unsigned int *)value];
			
		case kObjectiveCTypeUnsignedShort:
			return [NSNumber numberWithUnsignedShort:*(unsigned short *)value];
			
		case kObjectiveCTypeUnsignedLong:
			return [NSNumber numberWithUnsignedLong:*(unsigned long *)value];
			
		case kObjectiveCTypeUnsignedLongLong:
			return [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)value];
			
		case kObjectiveCTypeFloat:
			return [NSNumber numberWithFloat:*(float *)value];
			
		case kObjectiveCTypeDouble:
			return [NSNumber numberWithDouble:*(double *)value];
			
		case kObjectiveCTypeBool:
			return [NSNumber numberWithBool:*(_Bool *)value];
			
		case kObjectiveCTypeVoid:
			return STNull;
			
		case kObjectiveCTypeCString:
			return [NSString stringWithUTF8String:*(const char **)value];
			
		case kObjectiveCTypeCArray:
		case kObjectiveCTypePointer: {
			//Skip the initial ^ so the pointer knows what it actually contains.
			const char *pointerType = objcType + 1;
			STPointer *pointer = [STPointer pointerWithType:pointerType];
			memcpy(pointer.bytes, *(void **)value, pointer.length);
			
			return pointer;
		}
			
		case kObjectiveCTypeClass:
		case kObjectiveCTypeObject:
			return *(id *)value ?: STNull;
			
		case kObjectiveCTypeSelector:
			return NSStringFromSelector(*(SEL *)value);
			
		case kObjectiveCTypeStruct: {
			const STPrimitiveValueWrapperDescriptor *wrapperDescriptor = STTypeBridgeGetWrapperForType(type);
			return wrapperDescriptor->WrapDataWithSignature(wrapperDescriptor, value, type);
		}
			
		case kObjectiveCTypeUnion:
		case kObjectiveCTypeBitfield:
		case kObjectiveCTypeUnknown:
			NSCAssert(0, @"Type %s cannot be handled by the stein type bridge.", objcType);
			
		default:
			break;
	}
	
	return STNull;
}

void STTypeBridgeConvertObjectIntoType(id object, const char *objcType, void **value)
{
	const char *type = GetRelevantTypeForObjCType(objcType);
	
	switch (type[0])
	{
		case kObjectiveCTypeChar:
			*(char *)value = [object charValue];
			break;
			
		case kObjectiveCTypeInt:
			*(int *)value = [object intValue];
			break;
			
		case kObjectiveCTypeShort:
			*(short *)value = [object shortValue];
			break;
			
		case kObjectiveCTypeLong:
			*(long *)value = [object longValue];
			break;
			
		case kObjectiveCTypeLongLong:
			*(long long *)value = [object longLongValue];
			break;
			
		case kObjectiveCTypeUnsignedChar:
			*(unsigned char *)value = [object unsignedCharValue];
			break;
			
		case kObjectiveCTypeUnsignedInt:
			*(unsigned int *)value = [object unsignedIntValue];
			break;
			
		case kObjectiveCTypeUnsignedShort:
			*(unsigned short *)value = [object unsignedShortValue];
			break;
			
		case kObjectiveCTypeUnsignedLong:
			*(unsigned long *)value = [object unsignedLongValue];
			break;
			
		case kObjectiveCTypeUnsignedLongLong:
			*(unsigned long long *)value = [object unsignedLongLongValue];
			break;
			
		case kObjectiveCTypeFloat:
			*(float *)value = [object floatValue];
			break;
			
		case kObjectiveCTypeDouble:
			*(double *)value = [object doubleValue];
			break;
			
		case kObjectiveCTypeBool:
			*(_Bool *)value = [object boolValue];
			break;
			
		case kObjectiveCTypeVoid:
			*(void **)value = NULL;
			break;
			
		case kObjectiveCTypeCString:
			*(const char **)value = [object UTF8String];
			break;
			
		case kObjectiveCTypeCArray:
		case kObjectiveCTypePointer:
			if(object && object != STNull)
				*(Byte **)value = (Byte *)([object bytes]);
			else
				*(void **)value = NULL;
			
			break;
			
		case kObjectiveCTypeClass:
		case kObjectiveCTypeObject:
			if(object == STNull)
				*(id *)value = nil;
			else
				*(id *)value = object;
			break;
			
		case kObjectiveCTypeSelector:
			*(SEL *)value = NSSelectorFromString(object);
			break;
			
		case kObjectiveCTypeStruct:
			[(id < STPrimitiveValueWrapper >)object getValue:value forType:type];
			break;
			
		case kObjectiveCTypeUnion:
		case kObjectiveCTypeBitfield:
		case kObjectiveCTypeUnknown:
			NSCAssert(0, @"Type %s cannot be handled by the stein type bridge.", objcType);
			
		default:
			break;
	}
}

#pragma mark -
#pragma mark Struct Bridging

@interface STTypeBridgeGenericStructWrapper : NSObject < STPrimitiveValueWrapper >
{
	void *mValue;
	size_t mSizeOfValue;
	char *mObjcType;
}
- (id)initWithValue:(void *)value ofType:(const char *)objcType;
@end

#pragma mark -

static BOOL GenericStructCanWrapValueWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return YES;
}

static id < STPrimitiveValueWrapper > GenericStructWrapDataWithSignature(const STPrimitiveValueWrapperDescriptor *descriptor, void *data, const char *objcType)
{
	return [[[STTypeBridgeGenericStructWrapper alloc] initWithValue:data ofType:objcType] autorelease];
}

static size_t GenericStructSizeOfPrimitiveValue(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType)
{
	return sizeof(void *);
}

static STPrimitiveValueWrapperDescriptor const kGenericStructWrapperDescriptor = {
	.userData = NULL,
	.CanWrapValueWithSignature = GenericStructCanWrapValueWithSignature,
	.WrapDataWithSignature = GenericStructWrapDataWithSignature,
	.SizeOfPrimitiveValue = GenericStructSizeOfPrimitiveValue,
	.ObjCType = NULL,
};

#pragma mark -

@implementation STTypeBridgeGenericStructWrapper

- (void)dealloc
{
	if(mValue)
	{
		free(mValue);
		mValue = NULL;
	}
	
	if(mObjcType)
	{
		free(mObjcType);
		mObjcType = NULL;
	}
	
	[super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithValue:(void *)value ofType:(const char *)objcType
{
	NSParameterAssert(value);
	NSParameterAssert(objcType);
	
	if((self = [super init]))
	{
		mSizeOfValue = STTypeBridgeGetSizeOfObjCType(objcType);
		NSAssert((mSizeOfValue > 0), @"Could not get size of struct with type %s, oh dear.", objcType);
		
		mValue = NSAllocateCollectable(mSizeOfValue, 0);
		mObjcType = NSAllocateCollectable(strlen(objcType) + 1, 0);
		strcpy(mObjcType, objcType);
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Bridging

- (void)getValue:(void **)buffer forType:(const char *)objcType
{
	size_t sizeOfBuffer = STTypeBridgeGetSizeOfObjCType(objcType);
	NSAssert((sizeOfBuffer == mSizeOfValue), 
			 @"Buffer given to generic struct descriptor is %ld bytes, but the generic struct descriptor's buffer is %ld bytes.", sizeOfBuffer, mSizeOfValue);
	
	NSAssert(memcpy(buffer, mValue, mSizeOfValue),
			 @"Could not copy value into buffer.");
}

- (const STPrimitiveValueWrapperDescriptor *)descriptor
{
	return &kGenericStructWrapperDescriptor;
}

@end

#pragma mark -

const STPrimitiveValueWrapperDescriptor *StructWrapperRetainCallBack(CFAllocatorRef allocator, const STPrimitiveValueWrapperDescriptor *descriptor)
{
	STPrimitiveValueWrapperDescriptor *descriptorCopy = CFAllocatorAllocate(allocator, sizeof(STPrimitiveValueWrapperDescriptor), 0);
	memcpy(descriptorCopy, descriptor, sizeof(STPrimitiveValueWrapperDescriptor));
	return descriptorCopy;
}

void StructWrapperReleaseCallBack(CFAllocatorRef allocator, const STPrimitiveValueWrapperDescriptor *value)
{
	CFAllocatorDeallocate(allocator, (void *)value);
}

static CFStringRef StructWrapperCopyDescriptionCallBack(const STPrimitiveValueWrapperDescriptor *value)
{
	return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("<StructWrapperDescriptor:%p>"), value);
}

static Boolean StructWrapperEqualCallBack(const STPrimitiveValueWrapperDescriptor *value1, const STPrimitiveValueWrapperDescriptor *value2)
{
	return (value1->userData == value2->userData && 
			value1->CanWrapValueWithSignature == value2->CanWrapValueWithSignature && 
			value1->WrapDataWithSignature == value2->WrapDataWithSignature && 
			value1->SizeOfPrimitiveValue == value2->SizeOfPrimitiveValue);
}

static CFDictionaryValueCallBacks const kStructWrapperValueCallbacks = {
	.version = 0,
	.retain = (CFDictionaryRetainCallBack)StructWrapperRetainCallBack,
	.release = (CFDictionaryReleaseCallBack)StructWrapperReleaseCallBack,
	.copyDescription = (CFDictionaryCopyDescriptionCallBack)StructWrapperCopyDescriptionCallBack,
	.equal = (CFDictionaryEqualCallBack)StructWrapperEqualCallBack
};

static CFMutableDictionaryRef STTypeBridgeGetStructWrappers()
{
	static CFMutableDictionaryRef wrappers = NULL;
	
	OSMemoryBarrier();
	if(!wrappers)
	{
		CFMutableDictionaryRef array = CFDictionaryCreateMutable(kCFAllocatorDefault, 
																 0, 
																 &kCFTypeDictionaryKeyCallBacks, 
																 &kStructWrapperValueCallbacks);
		if(!OSAtomicCompareAndSwapPtrBarrier(NULL, array, (void * volatile *)&wrappers))
			CFRelease(array);
	}
	
	return wrappers;
}

#pragma mark -

void STTypeBridgeRegisterWrapper(NSString *name, const STPrimitiveValueWrapperDescriptor *wrapper)
{
	CFMutableDictionaryRef wrappers = STTypeBridgeGetStructWrappers();
	CFDictionarySetValue(wrappers, name, wrapper);
}

const STPrimitiveValueWrapperDescriptor *STTypeBridgeGetWrapperForType(const char *type)
{
	CFMutableDictionaryRef wrappers = STTypeBridgeGetStructWrappers();
	
	CFIndex dictionaryLength = CFDictionaryGetCount(wrappers);
	const STPrimitiveValueWrapperDescriptor *wrapperValues[dictionaryLength];
	CFDictionaryGetKeysAndValues(wrappers, NULL, (const void **)wrapperValues);
	
	for (CFIndex index = 0; index < dictionaryLength; index++)
	{
		const STPrimitiveValueWrapperDescriptor *wrapperDescriptor = wrapperValues[index];
		if(wrapperDescriptor->CanWrapValueWithSignature(wrapperDescriptor, type))
			return wrapperDescriptor;
	}
	
	return &kGenericStructWrapperDescriptor;
}

#pragma mark -
#pragma mark Type system conversions

static const void *CStringRetainCallBack(CFAllocatorRef allocator, const void *value)
{
	//Do nothing.
	return value;
}

static void CStringReleaseCallBack(CFAllocatorRef allocator, const void *value)
{
	//Do nothing.
}

static CFStringRef CStringCopyDescriptionCallBack(const void *value)
{
	return CFStringCreateWithCString(kCFAllocatorDefault, value, kCFStringEncodingUTF8);
}

static Boolean CStringEqualCallBack(const void *value1, const void *value2)
{
	return (strcmp(value1, value2) == 0);
}

static CFHashCode CStringHashCallBack(const void *value)
{
	return (CFHashCode)(value);
}

/*!
 @const
 @abstract	Predefined CFDictionaryKeyCallBacks structure containing a set of callbacks appropriate for use when the keys of a CFDictionary are all C string values.
 */
static CFDictionaryKeyCallBacks const kCStringDictionaryKeyCallbacks = {
	.version = 0,
	.retain = CStringRetainCallBack,
	.release = CStringReleaseCallBack,
	.copyDescription = CStringCopyDescriptionCallBack,
	.equal = CStringEqualCallBack,
	.hash = CStringHashCallBack,
};

#pragma mark -

/*!
 @function
 @abstract		Look up the ffi_type for an Objective-C type signature that describes a C struct.
 @param			signature	The Objective-C type signature describing the struct. May not be nil.
 @result		An equivalent ffi_type for the passed in `signature` that is fully initialized and ready for use.
 @discussion	This function caches struct types for use with libFFI. The first time this function is called
 with a unique signature, it will take longer then subsequent calls.
 */
static ffi_type *STTypeBridgeGetFFITypeForStruct(const char *objcType)
{
	NSCParameterAssert(objcType);
	
	//Look up the shared cached types, creating it if it doesn't exist.
	static CFMutableDictionaryRef sharedCachedTypes = NULL;
	
	OSMemoryBarrier();
	if(!sharedCachedTypes)
	{
		CFMutableDictionaryRef newCachedTypes = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCStringDictionaryKeyCallbacks, NULL);
		
		if(!OSAtomicCompareAndSwapPtrBarrier(NULL, newCachedTypes, (void **)&sharedCachedTypes))
			CFRelease(newCachedTypes);
	}
	
	//This nested function is used below for finding the end of structure's
	//in the ObjC type signature passed into this function.
	/*!
	 @function	findClosingCharacter
	 @abstract	This nested function searches a C string for a closing character, ignoring any nested character-pairs.
	 @param		openChar	The opening character that describes the beginning of a nested character-pair.
	 @param		closeChar	The closing character that describes the end of nested character-pairs, as well as the initial search started when invoking this function.
	 @param		start		The index to start the search at.
	 @param		string		The string to search.
	 @result	The location of the final closing character, or -1 if it could not be found.
	 */
	int(^findClosingCharacter)(unichar, unichar, int, const char *) = ^(unichar openChar, unichar closeChar, int start, const char *string) {
		int closingCharacterIndex = -1;
		for (int index = start; index < strlen(string); index++)
		{
			unichar token = string[index];
			if(token == openChar)
			{
				index = findClosingCharacter(openChar, closeChar, index + 1, string) + 1;
			}
			else if(token == closeChar)
			{
				closingCharacterIndex = index;
				break;
			}
		}
		
		return closingCharacterIndex;
	};
	
	//We first attempt to resolve the type from the cache, returning it if it exists.
	ffi_type *existingType = (ffi_type *)CFDictionaryGetValue(sharedCachedTypes, objcType);
	if(existingType)
		return existingType;
	
	@synchronized(@"mutex")
	{
		//There's a chance this has been set since we tried to acquire access to this section of code.
		existingType = (ffi_type *)CFDictionaryGetValue(sharedCachedTypes, objcType);
		if(existingType)
			return existingType;
		
		//If the type is not already cached, then we must build a new type.
		NSUInteger size, alignment;
		
		//The first thing we do is resolve the size and alignment of the contents of the type.
		NSGetSizeAndAlignment(objcType, &size, &alignment);
		
		//Allocate the ffi_type and set the basic fields.
		ffi_type *type = malloc(sizeof(ffi_type));
		type->size = size;
		type->alignment = alignment;
		type->type = FFI_TYPE_STRUCT;
		
		//Now its time to analyze the Objective-C type signature passed into this function.
		int numberOfSubtypes = 0;
		int indexOfEqualsCharacter = -1;
		for (int index = 0; index < strlen(objcType); index++)
		{
			const char typeCharacter = objcType[index];
			
			//We're looking for the right side of the type encoding.
			if(typeCharacter == '=')
			{
				//Once we find it, we set aside the index and continue on our way.
				indexOfEqualsCharacter = index;
				
				continue;
			}
			
			//When we've reached '}', we're at the end of the signature.
			if(typeCharacter == '}')
				break;
			
			//If we're on the right side of the index, all of the
			//stuff we find counts as a subtype in type signature.
			if(indexOfEqualsCharacter != -1)
			{
				//We move to the end of any nested structures/unions/etc.
				if(typeCharacter == '{')
				{
					index = findClosingCharacter('{', '}', index + 1, objcType);
				}
				else if((typeCharacter == '[') || (typeCharacter == '('))
				{
					//One day we might handle unions and C arrays.
					free(type);
					
					[NSException raise:NSInternalInconsistencyException 
								format:@"Unexpected union or C array encountered while caching a C struct's memory layout. Unions and C arrays are not supported by Caffeine."];
				}
				
				//Increment the number of subtypes and continue.
				numberOfSubtypes++;
			}
		}
		
		//Once we know how many subtypes we have, we can allocate the `elements`
		//section of our new ffi_type. We add 1 to `numberOfSubtypes` so libFFI
		//knows how long elements is (its null terminated).
		type->elements = calloc((numberOfSubtypes + 1), sizeof(ffi_type *));
		
		//Now that we've got the initial bookkeeping done, its time to actually make sense
		//of what was passed into this function, and to finish setting up the new ffi_type.
		int positionInSubtypes = 0;
		
		//We start on the right side of the equals character and enumerate from there.
		for (int index = (indexOfEqualsCharacter + 1); index < strlen(objcType); index++)
		{
			const char typeCharacter = objcType[index];
			
			//If we've encountered '}', we've reached the end of what we care about.
			if(typeCharacter == '}')
				break;
			
			ffi_type *structureSubtype;
			
			//If we've encountered a new substructure in the type we're caching.
			if(typeCharacter == '{')
			{
				//We find the end of the substructure's type signature.
				int endOfSubstructureType = findClosingCharacter('{', '}', index + 1, objcType) + 1;
				
				//Then we copy out the substructure's type signature.
				char substructureType[(endOfSubstructureType - index) + 1];
				strncpy(substructureType, (objcType + index), (endOfSubstructureType - index));
				
				//And resolve the substructure's type.
				structureSubtype = STTypeBridgeGetFFITypeForStruct(substructureType);
				
				index = endOfSubstructureType - 1;
			}
			else if((typeCharacter == '[') || (typeCharacter == '('))
			{
				//One day we might handle unions and C arrays.
				free(type->elements);
				free(type);
				
				[NSException raise:NSInternalInconsistencyException 
							format:@"Unexpected union or C array encountered while caching a C struct's memory layout. Unions and C arrays are not supported by Caffeine."];
			}
			else
			{
				//Any non-complex types, we just pass off to STTypeBridgeConvertObjCTypeToFFIType.
				const char subtype[] = { typeCharacter, '\0' };
				structureSubtype = STTypeBridgeConvertObjCTypeToFFIType(subtype);
			}
			
			if(positionInSubtypes >= numberOfSubtypes)
				break;
			
			type->elements[positionInSubtypes] = structureSubtype;
			positionInSubtypes++;
		}
		
		//We must null-terminate the ffi_type's element list, or libFFI will not be able to tell how long it is.
		type->elements[-1] = NULL;
		
		//Store the type for future use.
		CFDictionarySetValue(sharedCachedTypes, objcType, type);
		
		//And return it for use.
		return type;
	}
	
	return NULL;
}

ffi_type *STTypeBridgeConvertObjCTypeToFFIType(const char *objcType)
{
	const char *type = GetRelevantTypeForObjCType(objcType);
	
	switch (type[0])
	{
		case kObjectiveCTypeChar: return &ffi_type_schar;
		case kObjectiveCTypeInt: return &ffi_type_sint;
		case kObjectiveCTypeShort: return &ffi_type_sshort;
		case kObjectiveCTypeLong: return &ffi_type_slong;
		case kObjectiveCTypeLongLong: return &ffi_type_sint64;
		case kObjectiveCTypeUnsignedChar: return &ffi_type_uchar;
		case kObjectiveCTypeUnsignedInt: return &ffi_type_uint;
		case kObjectiveCTypeUnsignedShort: return &ffi_type_ushort;
		case kObjectiveCTypeUnsignedLong: return &ffi_type_ulong;
		case kObjectiveCTypeUnsignedLongLong: return &ffi_type_uint64;
		case kObjectiveCTypeFloat: return &ffi_type_float;
		case kObjectiveCTypeDouble: return &ffi_type_double;
		case kObjectiveCTypeBool: return &ffi_type_uchar;
		case kObjectiveCTypeVoid: return &ffi_type_void;
		case kObjectiveCTypeCArray:
		case kObjectiveCTypePointer:
		case kObjectiveCTypeCString:
		case kObjectiveCTypeObject:
		case kObjectiveCTypeClass:
		case kObjectiveCTypeSelector:
			return &ffi_type_pointer;
			
		case kObjectiveCTypeStruct: return STTypeBridgeGetFFITypeForStruct(type);
		case kObjectiveCTypeUnion:
		case kObjectiveCTypeUnknown:
		default:
			[NSException raise:NSInternalInconsistencyException 
						format:@"Type unknown to Caffeine encountered."];
	}
	
	return &ffi_type_void;
}

#pragma mark -

NSString *STTypeBridgeGetObjCTypeForHumanReadableType(NSString *type)
{
	if([type hasPrefix:@"^"])
		return [@"^" stringByAppendingString:STTypeBridgeGetObjCTypeForHumanReadableType([type substringFromIndex:1])];
	
	if([type isEqualToString:@"char"] || [type isEqualToString:@"BOOL"])
		return @"c";
	else if([type isEqualToString:@"int"])
		return @"i";
	else if([type isEqualToString:@"short"])
		return @"s";
	else if([type isEqualToString:@"long"])
		return @"l";
	else if([type isEqualToString:@"longlong"])
		return @"q";
	else if([type isEqualToString:@"uchar"])
		return @"C";
	else if([type isEqualToString:@"uint"])
		return @"I";
	else if([type isEqualToString:@"ushort"])
		return @"S";
	else if([type isEqualToString:@"ulong"])
		return @"L";
	else if([type isEqualToString:@"ulonglong"])
		return @"Q";
	else if([type isEqualToString:@"float"])
		return @"f";
	else if([type isEqualToString:@"double"])
		return @"d";
	else if([type isEqualToString:@"_bool"])
		return @"B";
	else if([type isEqualToString:@"void"] || [type isEqualToString:@"IBAction"]) //IBAction is just an alias for void.
		return @"v";
	else if([type isEqualToString:@"Class"])
		return @"#";
	else if([type isEqualToString:@"id"] || (NSClassFromString(type) != nil))
		return @"@";
	else if([type isEqualToString:@"SEL"])
		return @":";
	
	CFMutableDictionaryRef wrappers = STTypeBridgeGetStructWrappers();
	const STPrimitiveValueWrapperDescriptor *descriptor = CFDictionaryGetValue(wrappers, type);
	if(descriptor && descriptor->ObjCType)
		return [NSString stringWithUTF8String:descriptor->ObjCType(descriptor)];
	
	return @"?";
}
