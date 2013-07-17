/*
 *  SteinDefines.h
 *  stein
 *
 *  Created by Kevin MacWhinnie on 2009/12/13.
 *  Copyright 2009 Stein Language. All rights reserved.
 *
 */

#ifndef SteinDefines_h
#define SteinDefines_h 1

#pragma mark Goop

#if __cplusplus
#	define ST_EXTERN	extern "C"
#else
#	define ST_EXTERN	extern
#endif /* __cplusplus */

#define ST_INLINE	static inline

#define ST_FLAG_IS_SET(bitfield, flag) ((flag & bitfield) == flag)

#pragma mark - Defines

///Set to 1 to have Stein include wrappers for the RoundaboutKit built ins.
#define ST_INCLUDE_RK_BUILTINS  1

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import "SteinException.h"

#pragma mark - Tools

///The name of the variable used to track a method's superclass.
///
///When a class is created in Stein, every method of that class
///has the class's superclass associated with it. This is necessary
///to prevent infinite loops in the `super` message-functor.
ST_EXTERN NSString *const kSTSuperclassVariableName;

///The name of the variable used to track the real (human readable) name of a class.
NSString *const kSTClassNameVariableName;

#pragma mark - Globals

///The result of this macro is the value used to represent 'null' in Stein.
#define STNull	[NSNull null]

ST_INLINE BOOL STIsNull(id object)
{
	return (!object || [object isEqual:STNull]);
}

#pragma mark -

///The result of this macro is the value used to represent 'true' in Stein.
#define STTrue	((__bridge NSNumber *)kCFBooleanTrue) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

///The result of this macro is the value used to represent 'false' in Stein.
#define STFalse	((__bridge NSNumber *)kCFBooleanFalse) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

ST_INLINE BOOL STIsTrue(id object)
{
	return ((object != nil) && (object != STNull) && 
			[object respondsToSelector:@selector(boolValue)] && [object boolValue]);
}

#pragma mark - Types

///The STCreationLocation class is used to describe where
///a list or symbol was created in the context of a file.
@interface STCreationLocation : NSObject

///Initialize the receiver with a given file string.
- (id)initWithFile:(NSString *)file;

#pragma mark - Properties

///The file in which the expression was first read.
@property (nonatomic, copy) NSString *file;

///The line on which the expression was created.
@property (nonatomic) NSUInteger line;

///The offset (from the beginning of the line) on which the expression was created.
@property (nonatomic) NSUInteger column;

@end

#pragma mark - Errors

///Raises an exception for an issue encountered by an expression at a specified location.
///
/// \param		expressionLocation	The location of the issue.
/// \param		format				The string describing the issue. Interpreted as a format-string.
/// \param		...					The parameters of the format-string.
///
///This function always raises and as such never returns.
ST_EXTERN void STRaiseIssue(STCreationLocation *expressionLocation, NSString *format, ...);

#endif /* __OBJC__ */

#endif /* SteinDefines_h */
