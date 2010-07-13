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

#define ST_FLAG_IS_SET(bitfield, flag) ((flag & bitfield) == flag)

#pragma mark -
#pragma mark Options

//Uncomment the following line to have Stein use unique names for classes in the runtime.
//This should be used whenever multiple Stein interpreters will be running side by side
//with in the same runtime executable space.
//#define ST_USE_UNIQUE_RUNTIME_CLASS_NAMES 1

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <Stein/SteinException.h>

#pragma mark -
#pragma mark Tools

/*!
 @abstract	Returns the Stein framework bundle. Useful for looking up resources.
 */
ST_EXTERN NSBundle *SteinBundle();

#pragma mark -
#pragma mark Globals

/*!
 @abstract	The result of this macro is the value used to represent 'null' in Stein.
 */
#define STNull	((id)kCFBooleanFalse)

ST_INLINE BOOL STIsNull(id object)
{
	return (!object || object == STNull);
}

#pragma mark -

/*!
 @abstract	The result of this macro is the value used to represent 'true' in Stein.
 */
#define STTrue	((NSNumber *)kCFBooleanTrue) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

/*!
 @abstract	The result of this macro is the value used to represent 'false' in Stein.
 */
#define STFalse	((NSNumber *)kCFBooleanFalse) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

ST_INLINE BOOL STIsTrue(id object)
{
	return ((object != nil) && (object != STNull) && 
			[object respondsToSelector:@selector(boolValue)] && [object boolValue]);
}

#pragma mark -
#pragma mark Types

typedef struct STCreationLocation {
	/*!
	 @struct	STCreationLocation
	 @abstract	The STCreationLocation type is used to describe where a list
				or symbol was created in the context of a file.
	 
	 @field		file	The file in which the expression was first read.
	 @field		line	The line on which the expression was created.
	 @field		offset	The offset (from the beginning of the line) on which the expression was created.
	 */
	NSString *file;
	NSUInteger line;
	NSUInteger column;
} STCreationLocation;

#pragma mark -
#pragma mark Errors

/*!
 @abstract		Raises an exception for an issue encountered by an expression at a specified location.
 @param			expressionLocation	The location of the issue.
 @param			format				The string describing the issue. Interpreted as a format-string.
 @param			...					The parameters of the format-string.
 @discussion	This function always raises and as such never returns.
 */
ST_EXTERN void STRaiseIssue(STCreationLocation expressionLocation, NSString *format, ...);

#endif /* __OBJC__ */
