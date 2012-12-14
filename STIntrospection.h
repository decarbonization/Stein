//
//  STIntrospection.h
//  Stein
//
//  Created by Peter MacWhinnie on 5/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

///This class is used to represent methods for Caffeine introspection.
@interface STMethod : NSObject
{
	Class mClass;
	Method mMethod;
}
/// \ignore
- (id)initWithClass:(Class)class method:(Method)method;

///The class this method belongs to.
@property (readonly) Class methodClass;

///Whether or not this method is an instance method.
@property (readonly) BOOL isInstanceMethod;

///The name of this method.
@property (readonly) NSString *name;

///The number of arguments this method takes.
@property (readonly) NSInteger numberOfArguments;

///The type encoding of the method.
@property (readonly) NSString *typeEncoding;

///The implementation of this method.
@property IMP implementation;
@end

#pragma mark -

///This class is used to represent instance variables in Caffeine introspection.
@interface STIvar : NSObject
{
	Class mClass;
	Ivar mIvar;
}
/// \ignore
- (id)initWithClass:(Class)class ivar:(Ivar)ivar;

///The class this ivar belongs to.
@property (readonly) Class ivarClass;

///The name of this ivar.
@property (readonly) NSString *name;

///The offset of this ivar.
@property (readonly) NSInteger offset;

///The type encoding of this ivar.
@property (readonly) NSString *typeEncoding;

@end

#pragma mark -

///This category adds introspection methods to NSObject.
@interface NSObject (STIntrospection)

///Get a list of methods an object implements.
+ (NSArray *)methods;

///Get a list of methods an object implements.
- (NSArray *)methods;

#pragma mark -

///Get the list of ivars an object has.
+ (NSArray *)ivars;

///Get the list of ivars an object has.
- (NSArray *)ivars;

#pragma mark -

///Get the subclasses of the receiver.
+ (NSArray *)subclasses;

///Get the subclasses of the receiver.
- (NSArray *)subclasses;

@end
