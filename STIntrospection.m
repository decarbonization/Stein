//
//  STIntrospection.m
//  Stein
//
//  Created by Kevin MacWhinnie on 5/26/09.
//  Copyright 2009 Kevin MacWhinnie. All rights reserved.
//

#import "STIntrospection.h"

@implementation STMethod

#pragma mark Creation

- (id)initWithClass:(Class)class method:(Method)method
{
	if((self = [super init]))
	{
		mClass = class;
		mMethod = method;
		
		return self;
	}
	return nil;
}

#pragma mark - Identity

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@[%@ %@]>", [self class], self, self.isInstanceMethod? @"-" : @"+", self.methodClass, self.name];
}

#pragma mark - Properties

@synthesize methodClass = mClass;

- (BOOL)isInstanceMethod
{
	return (class_getInstanceMethod(mClass, method_getName(mMethod)) != nil);
}

- (NSString *)name
{
	SEL name = method_getName(mMethod);
	NSAssert1(name != nil, @"Could not get method name for class %@.", mClass);
	return NSStringFromSelector(name);
}

- (NSInteger)numberOfArguments
{
	return method_getNumberOfArguments(mMethod);
}

- (NSString *)typeEncoding
{
	const char *typeEncoding = method_getTypeEncoding(mMethod);
	NSAssert1(typeEncoding != nil, @"Could not get method type encoding for class %@.", mClass);
	return [NSString stringWithUTF8String:typeEncoding];
}

#pragma mark -

- (void)setImplementation:(IMP)implementation
{
	//The runtime is thread safe.
	method_setImplementation(mMethod, implementation);
}

- (IMP)implementation
{
	return method_getImplementation(mMethod);
}

@end

#pragma mark -

@implementation STIvar

#pragma mark Initialization

- (id)initWithClass:(Class)class ivar:(Ivar)ivar
{
	if((self = [super init]))
	{
		mClass = class;
		mIvar = ivar;
		
		return self;
	}
	return nil;
}

#pragma mark - Identity

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p + %ld = %@(%@)>", [self class], self, self.offset, self.name, self.typeEncoding];
}

#pragma mark - Properties

@synthesize ivarClass = mClass;

- (NSString *)name
{
	const char *name = ivar_getName(mIvar);
	NSAssert1(name != nil, @"Could not get ivar name for class %@.", mClass);
	return [NSString stringWithUTF8String:name];
}

- (NSInteger)offset
{
	return ivar_getOffset(mIvar);
}

- (NSString *)typeEncoding
{
	const char *typeEncoding = ivar_getTypeEncoding(mIvar);
	NSAssert1(typeEncoding != nil, @"Could not get ivar type encoding for class %@.", mClass);
	return [NSString stringWithUTF8String:typeEncoding];
}

@end

#pragma mark -

@implementation NSObject (STIntrospection)

+ (NSArray *)methods
{
	unsigned int count = 0;
	Method *methods = class_copyMethodList([self class], &count);
	if(!methods) return [NSArray array];
	
	NSMutableArray *methodArray = [NSMutableArray array];
	
	for (int index = 0; index < count; index++)
	{
		STMethod *method = [[STMethod alloc] initWithClass:self method:methods[index]];
		[methodArray addObject:method];
	}
	
	free(methods);
	
	return methodArray;
}

- (NSArray *)methods
{
	return [[self class] methods];
}

#pragma mark -

+ (NSArray *)ivars
{
	unsigned int count = 0;
	Ivar *ivars = class_copyIvarList(self, &count);
	if(!ivars) return [NSArray array];
	
	NSMutableArray *ivarArray = [NSMutableArray array];
	
	for (int index = 0; index < count; index++)
	{
		STIvar *ivar = [[STIvar alloc] initWithClass:self ivar:ivars[index]];
		[ivarArray addObject:ivar];
	}
	
	free(ivars);
	
	return ivarArray;
}

- (NSArray *)ivars
{
	return [[self class] ivars];
}

#pragma mark -

///This is a functional variant of NSObject#isKindOfClass:
static BOOL class_isKindOfClass(Class left, Class right)
{
	if(class_isMetaClass(left) || class_isMetaClass(right))
		return NO;
	
	Class class = left;
	do {
		if(class == right)
			return YES;
		
		class = class_getSuperclass(class);
	} while (class != nil);
	
	return NO;
}

+ (NSArray *)subclasses
{
	int count = objc_getClassList(NULL, 0);
	if(count > 0)
	{
		Class classes[count]; //Yay static allocation.
		objc_getClassList(classes, count);
		
		NSMutableArray *classArray = [NSMutableArray array];
		for (int index = 0; index < count; index++)
		{
			Class class = classes[index];
			if(class != [self class] && class_isKindOfClass(class, self))
				[classArray addObject:class];
		}
		
		return classArray;
	}
	
	return [NSArray array];
}

- (NSArray *)subclasses
{
	return [self subclasses];
}

@end
