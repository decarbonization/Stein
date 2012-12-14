/*
 *  SteinDefines.h
 *  stein
 *
 *  Created by Peter MacWhinnie on 2009/12/13.
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

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <Stein/SteinException.h>

#pragma mark - Tools

///Returns the Stein framework bundle. Useful for looking up resources.
ST_EXTERN NSBundle *SteinBundle();

///The name of the variable used to track a method's superclass.
///
///When a class is created in Stein, every method of that class
///has the class's superclass associated with it. This is necessary
///to prevent infinite loops in the `super` message-functor.
ST_EXTERN NSString *const kSTSuperclassVariableName;

///If set to YES then Stein will use unique names for the classes it registers in the runtime.
///This option should be enabled if multiple independent instances of Stein are going to be
///used side by side in a program. Default value is NO.
ST_EXTERN BOOL STUseUniqueRuntimeClassNames;

#pragma mark - Globals

///The result of this macro is the value used to represent 'null' in Stein.
#define STNull	((id)kCFBooleanFalse)

ST_INLINE BOOL STIsNull(id object)
{
	return (!object || object == STNull);
}

#pragma mark -

///The result of this macro is the value used to represent 'true' in Stein.
#define STTrue	((NSNumber *)kCFBooleanTrue) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

///The result of this macro is the value used to represent 'false' in Stein.
#define STFalse	((NSNumber *)kCFBooleanFalse) /* CFBoolean is toll-free bridged with NSNumber. This saves us a message. */

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
