//
//  STTypeBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
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

/*!
 @function
 @abstract	Register a type wrapper into the Stein type bridge.
 @param		name	The name of the type wrapper. May be nil.
 @param		wrapper	A wrapper descriptor value. Will be copied in. May not be NULL.
 */
ST_EXTERN void STTypeBridgeRegisterWrapper(NSString *name, const STPrimitiveValueWrapperDescriptor *wrapper);

/*!
 @function
 @abstract	Look up a type wrapper in the Stein type bridge for a specified Objective-C type string.
 @param		type	The Objective-C type of the value the wrapper is to wrap itself around. May not be NULL.
 @result	A value wrapper descriptor describing a wrapper that is suitable for the specified type.
 */
ST_EXTERN const STPrimitiveValueWrapperDescriptor *STTypeBridgeGetWrapperForType(const char *type);

#pragma mark -

/*!
 @function
 @abstract	Look up the size of a specified Objective-C type.
 */
ST_EXTERN size_t STTypeBridgeGetSizeOfObjCType(const char *objcType);

/*!
 @function
 @abstract		Convert a raw primitive value into an object.
 @param			value		The primitive value to convert. May not be NULL.
 @param			objcType	The type of the primitive value to convert. May not be NULL.
 @result		An object representing the passed in value.
 @discussion	This function raises an assertion if the value cannot be turned into an object.
 */
ST_EXTERN id STTypeBridgeConvertValueOfTypeIntoObject(void *value, const char *objcType);

/*!
 @function
 @abstract	Convert an object into a primitive value.
 @param		object	The object to convert into a primitive value. May not be nil.
 @param		type	The type the object is to be converted into. May not be NULL.
 @param		value	A buffer large enough to hold the primitive representation of the object. May not be NULL.
 */
ST_EXTERN void STTypeBridgeConvertObjectIntoType(id object, const char *type, void **value);

#pragma mark -

/*!
 @function
 @abstract		Look up the Objective-C type for a specified human-readable type.
 @param			type	The human-readable type who we're to look up an Objective-C type for.
 @result		An Objective-C type string.
 @discussion	Human-readable types are currently only used in method definitions.
 */
ST_EXTERN NSString *STTypeBridgeGetObjCTypeForHumanReadableType(NSString *type);
