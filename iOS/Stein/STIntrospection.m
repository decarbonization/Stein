//
//  STIntrospection.m
//  Stein
//
//  Created by Kevin MacWhinnie on 5/26/09.
//  Copyright 2009 Kevin MacWhinnie. All rights reserved.
//

#import "STIntrospection.h"
#import "STTypeBridge.h"

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

- (NSString *)prettyDescription
{
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(mMethod)];
    NSMutableString *prettyDescription = [NSMutableString stringWithFormat:@"%@ (%@)",
                                          self.isInstanceMethod? @"-" : @"+",
                                          STTypeBridgeGetHumanReadableTypeForObjCType(@([signature methodReturnType]))];
    
    if([self.name rangeOfString:@":"].location != NSNotFound)
    {
        NSArray *subnames = [self.name componentsSeparatedByString:@":"];
        [subnames enumerateObjectsUsingBlock:^(NSString *subname, NSUInteger index, BOOL *stop) {
            if([subname length] == 0)
                return;
            
            [prettyDescription appendFormat:@"%@:(%@)v%d ", subname, STTypeBridgeGetHumanReadableTypeForObjCType(@([signature getArgumentTypeAtIndex:index + 2])), index + 1];
        }];
    }
    else if([signature numberOfArguments] > 2)
    {
        
        [prettyDescription appendFormat:@"%@(", self.name];
        for (NSUInteger index = 2; index < [signature numberOfArguments]; index++)
            [prettyDescription appendFormat:@"%@, ", STTypeBridgeGetHumanReadableTypeForObjCType(@([signature getArgumentTypeAtIndex:index]))];
        [prettyDescription deleteCharactersInRange:NSMakeRange([prettyDescription length] - 2, 2)];
        [prettyDescription appendString:@")"];
    }
    else
    {
        [prettyDescription appendString:self.name];
    }
    
    return prettyDescription;
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
	return [NSString stringWithFormat:@"<%@:%p + %d = %@(%@)>", [self class], self, self.offset, self.name, self.typeEncoding];
}

- (NSString *)prettyDescription
{
    return [NSString stringWithFormat:@"%@ @%@", STTypeBridgeGetHumanReadableTypeForObjCType(self.typeEncoding), self.name];
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
	unsigned int instanceMethodCount = 0;
	Method *instanceMethods = class_copyMethodList([self class], &instanceMethodCount);
	
    unsigned int classMethodCount = 0;
    Method *classMethods = class_copyMethodList(object_getClass([self class]), &classMethodCount);
    
	NSMutableArray *methodArray = [NSMutableArray array];
	
    for (int index = 0; index < classMethodCount; index++)
	{
		STMethod *method = [[STMethod alloc] initWithClass:self method:classMethods[index]];
		[methodArray addObject:method];
	}
    
	for (int index = 0; index < instanceMethodCount; index++)
	{
		STMethod *method = [[STMethod alloc] initWithClass:self method:instanceMethods[index]];
		[methodArray addObject:method];
	}
	
	free(instanceMethods);
	
	NSArray *descriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"isInstanceMethod" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES],
    ];
	return [methodArray sortedArrayUsingDescriptors:descriptors];
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

static BOOL CStringHasPrefix(const char *string, const char *prefix)
{
	if(strlen(prefix) > strlen(string))
		return NO;
	
	int prefixLength = strlen(prefix);
	for (int index = 0; index < prefixLength; index++)
	{
		if(string[index] != prefix[index])
		{
			return NO;
		}
	}
	
	return YES;
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
			if(class != [self class] &&
               !CStringHasPrefix(class_getName(class), "$__") &&
               class_isKindOfClass(class, self))
            {
				[classArray addObject:class];
            }
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
