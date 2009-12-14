//
//  STTypeBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>

typedef struct STPrimitiveValueWrapperDescriptor STPrimitiveValueWrapperDescriptor;

/*!
 @prototype
 @abstract	This prototype describes the methods an object must implement if it wants to wrap a primitive value in the Stein type bridge.
 */
@protocol STPrimitiveValueWrapper < NSObject >

/*!
 @method
 @abstract	Place the receiver's value into a buffer that has been prepared for a specified type.
 @param		buffer		The buffer the receiver is to place it's primitive value into. May not be NULL.
 @param		objcType	The type that was used when creating the buffer. May not be NULL.
 */
- (void)getValue:(void **)buffer forType:(const char *)objcType;

/*!
 @method
 @abstract	Returns the descriptor that was used to create the receiver.
 */
- (const STPrimitiveValueWrapperDescriptor *)descriptor;

@end

struct STPrimitiveValueWrapperDescriptor {
	/*!
	 @struct	STPrimitiveValueWrapperDescriptor
	 @abstract	This type is used to describe primitive value wrappers in the Stein type bridge system.
	 
	 @field		userData
					An arbitrary pointer to program-defined data.
	 
	 @field		CanWrapValueWithSignature
					A pointer to a function that will indicate rather or not the wrapper object this descriptor is describing can wrap a specified value type. This field may not be NULL.
	 
	 @field		WrapDataWithSignature
					A pointer to a function that will produce a wrapped object for a specified value of a specified type. This field may not be NULL.
	 @field		SizeOfPrimitiveValue
					A pointer to a function that will indicate the size of the value the struct wrapper wraps. This field may not be NULL.
	 
	 @field		ObjCType
					A pointer to a function that will return the ObjC type that the type bridge is wrapping. This field may be NULL if it is inconvenient/impossible to provide an ObjC type.
	 */
	void *userData;
	
	BOOL(*CanWrapValueWithSignature)(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType);
	
	id < STPrimitiveValueWrapper >(*WrapDataWithSignature)(const STPrimitiveValueWrapperDescriptor *descriptor, void *data, const char *objcType);
	
	size_t(*SizeOfPrimitiveValue)(const STPrimitiveValueWrapperDescriptor *descriptor, const char *objcType);
	
	const char *(*ObjCType)(const STPrimitiveValueWrapperDescriptor *descriptor);
};

void STTypeBridgeRegisterWrapper(NSString *name, const STPrimitiveValueWrapperDescriptor *wrapper);
ST_EXTERN const STPrimitiveValueWrapperDescriptor *STTypeBridgeGetWrapperForType(const char *type);

#pragma mark -

ST_EXTERN size_t STTypeBridgeSizeofObjCType(const char *objcType);
ST_EXTERN id STTypeBridgeConvertValueOfTypeIntoObject(void *value, const char *objcType);
ST_EXTERN void STTypeBridgeConvertObjectIntoType(id object, const char *type, void **value);

#pragma mark -

ST_EXTERN NSString *STTypeBridgeGetObjCTypeForHumanReadableType(NSString *type);
