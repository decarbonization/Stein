//
//  STTypeBridge.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>

typedef struct StructWrapperDescriptor StructWrapperDescriptor;

@protocol StructWrapper < NSObject >

- (void)getValue:(void **)buffer forType:(const char *)objcType; 
- (const StructWrapperDescriptor *)descriptor;

@end

struct StructWrapperDescriptor {
	void *userData;
	BOOL(*CanWrapStructWithSignature)(const StructWrapperDescriptor *descriptor, const char *objcType);
	id < StructWrapper >(*WrapStructDataWithSignature)(const StructWrapperDescriptor *descriptor, void *data, const char *objcType);
	size_t(*SizeOfWrappedValue)(const StructWrapperDescriptor *descriptor, const char *objcType);
};

ST_EXTERN void STTypeBridgeRegisterStructWrapper(const StructWrapperDescriptor *wrapper);
ST_EXTERN const StructWrapperDescriptor *STTypeBridgeStructWrapperForType(const char *type);

ST_EXTERN size_t STTypeBridgeSizeofObjCType(const char *objcType);
ST_EXTERN id STTypeBridgeConvertValueOfTypeIntoObject(void *value, const char *objcType);
ST_EXTERN void STTypeBridgeConvertObjectIntoType(id object, const char *type, void **value);
