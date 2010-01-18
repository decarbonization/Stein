//
//  STIntrospection.h
//  Stein
//
//  Created by Peter MacWhinnie on 5/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

/*!
 @class		STMethod
 @abstract	This class is used to represent methods for Caffeine introspection.
 */
@interface STMethod : NSObject
{
	Class mClass;
	Method mMethod;
}
///@ignore
- (id)initWithClass:(Class)class method:(Method)method;

/*!
 @property	methodClass
 @abstract	The class this method belongs to.
 */
@property (readonly) Class methodClass;

/*!
 @property	isInstanceMethod
 @abstract	Whether or not this method is an instance method.
 */
@property (readonly) BOOL isInstanceMethod;

/*!
 @property	name
 @abstract	The name of this method.
 */
@property (readonly) NSString *name;

/*!
 @property	numberOfArguments
 @abstract	The number of arguments this method takes.
 */
@property (readonly) NSInteger numberOfArguments;

/*!
 @property	typeEncoding
 @abstract	The type encoding of the method.
 */
@property (readonly) NSString *typeEncoding;

/*!
 @property	implementation
 @abstract	The implementation of this method.
 */
@property IMP implementation;
@end

#pragma mark -

/*!
 @class		STIvar
 @abstract	This class is used to represent instance variables in Caffeine introspection.
 */
@interface STIvar : NSObject
{
	Class mClass;
	Ivar mIvar;
}
///@ignore
- (id)initWithClass:(Class)class ivar:(Ivar)ivar;

/*!
 @property	methodClass
 @abstract	The class this ivar belongs to.
 */
@property (readonly) Class ivarClass;

/*!
 @property	name
 @abstract	The name of this ivar.
 */
@property (readonly) NSString *name;

/*!
 @property	typeEncoding
 @abstract	The offset of this ivar.
 */
@property (readonly) NSInteger offset;

/*!
 @property	typeEncoding
 @abstract	The type encoding of this ivar.
 */
@property (readonly) NSString *typeEncoding;

@end

#pragma mark -

/*!
 @category	NSObjectWithIntrospection
 @abstract	This category adds introspection methods to NSObject.
 */
@interface NSObject (STIntrospection)

/*!
 @method	methods
 @abstract	Get a list of methods an object implements.
 */
+ (NSArray *)methods;

/*!
 @method	methods
 @abstract	Get a list of methods an object implements.
 */
- (NSArray *)methods;

#pragma mark -

/*!
 @method	ivars
 @abstract	Get the list of ivars an object has.
 */
+ (NSArray *)ivars;

/*!
 @method	ivars
 @abstract	Get the list of ivars an object has.
 */
- (NSArray *)ivars;

#pragma mark -

/*!
 @method	subclasses
 @abstract	Get the subclasses of the receiver.
 */
+ (NSArray *)subclasses;

/*!
 @method	subclasses
 @abstract	Get the subclasses of the receiver.
 */
- (NSArray *)subclasses;

@end
