/*
 *  SteinDefines.h
 *  stein
 *
 *  Created by Peter MacWhinnie on 2009/12/13.
 *  Copyright 2009 Stein Language. All rights reserved.
 *
 */

#pragma once

#pragma mark Goop

#if __cplusplus
#	define ST_EXTERN	extern "C"
#else
#	define ST_EXTERN	extern
#endif /* __cplusplus */

#define ST_INLINE	static inline

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark Tools

/*!
 @function
 @abstract	Returns the Stein framework bundle. Useful for looking up resources.
 */
ST_EXTERN NSBundle *SteinBundle();

#pragma mark -
#pragma mark Globals

/*!
 @defined
 @abstract	The result of this macro is the value used to represent 'null' in Stein.
 */
#define STNull	((id)kCFBooleanFalse) /* CFNull is toll-free bridged with NSNull. This saves us a message. */

ST_INLINE BOOL STIsNull(id object)
{
	return (!object || object == STNull);
}

#pragma mark -

/*!
 @defined
 @abstract	The result of this macro is the value used to represent 'true' in Stein.
 */
#define STTrue	((NSNumber *)kCFBooleanTrue) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

/*!
 @defined
 @abstract	The result of this macro is the value used to represent 'false' in Stein.
 */
#define STFalse	((NSNumber *)kCFBooleanFalse) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

ST_INLINE BOOL STIsTrue(id object)
{
	return [object isTrue];
}

#pragma mark -
#pragma mark Types

typedef struct STCreationLocation {
	/*!
	 @struct	STCreationLocation
	 @abstract	The STCreationLocation type is used to describe where a list
				or symbol was created in the context of a file.
	 
	 @field		line	The line on which the expression was created.
	 @field		offset	The offset (from the beginning of the line) on which the expression was created.
	 */
	NSUInteger line;
	NSUInteger offset;
} STCreationLocation;

#pragma mark -
#pragma mark Errors

ST_EXTERN NSString *const SteinException;

ST_EXTERN void STRaiseIssue(STCreationLocation expressionLocation, NSString *format, ...);

#endif /* __OBJC__ */
