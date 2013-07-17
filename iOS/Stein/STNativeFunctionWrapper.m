//
//  STNativeFunctionWrapper.m
//  stein
//
//  Created by Kevin MacWhinnie on 10/1/14.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STNativeFunctionWrapper.h"
#import "STList.h"
#import "STTypeBridge.h"
#import "NSObject+SteinTools.h"
#import <sys/mman.h>

ST_EXTERN ffi_type *STTypeBridgeConvertObjCTypeToFFIType(const char *objcType); //from STTypeBridge.m

@implementation STNativeFunctionWrapper

#pragma mark Bridging

///This function serves as the bridge between libFFI and STNativeFunctionWrapper.
static void FunctionBridge(ffi_cif *clossureInformation, void *returnBuffer, void **arguments, void *userData)
{
	STNativeFunctionWrapper *self = (__bridge STNativeFunctionWrapper *)userData;
	
	STList *argumentsAsObjects = [STList new];
	NSUInteger numberOfArguments = [self->mSignature numberOfArguments];
	for (NSUInteger index = 0; index < numberOfArguments; index++)
		[argumentsAsObjects addObject:STTypeBridgeConvertValueOfTypeIntoObject(arguments[index], [self->mSignature getArgumentTypeAtIndex:index])];
	
	id resultObject = STFunctionApply(self->mFunction, argumentsAsObjects);
	STTypeBridgeConvertObjectIntoType(resultObject, [self->mSignature methodReturnType], returnBuffer);
}

#pragma mark - Destruction

- (void)finalize
{
	if(munmap(mClosure, sizeof(mClosure)) == -1)
		NSLog(@"uh oh, munmap failed with error %d", errno);
	
	if(mArgumentTypes)
	{
		free(mArgumentTypes);
		mArgumentTypes = NULL;
	}
	
	if(mClosureInformation)
	{
		free(mClosureInformation);
		mClosureInformation = NULL;
	}
	
	[super finalize];
}

#pragma mark - Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithFunction:(NSObject <STFunction> *)function signature:(NSMethodSignature *)signature
{
	NSParameterAssert(function);
	NSParameterAssert(signature);
	
	NSAssert(![function isKindOfClass:[STNativeFunctionWrapper class]], 
			 @"You cannot wrap a native function wrapper.");
	
	if((self = [super init]))
	{
		mFunction = function;
		mSignature = signature;
		
		NSUInteger numberOfArguments = [mSignature numberOfArguments];
		
		//Resolve the argument types
		mArgumentTypes = calloc(sizeof(ffi_type *), numberOfArguments);
		
		for (NSUInteger index = 0; index < numberOfArguments; index++)
			mArgumentTypes[index] = STTypeBridgeConvertObjCTypeToFFIType([mSignature getArgumentTypeAtIndex:index]);
		
		mReturnType = STTypeBridgeConvertObjCTypeToFFIType([mSignature methodReturnType]);
		
		//Create the closure
		mClosureInformation = malloc(sizeof(ffi_cif));
		
		mClosure = mmap(NULL, sizeof(ffi_closure), (PROT_READ | PROT_WRITE), (MAP_ANON | MAP_PRIVATE), -1, 0);
		NSAssert((mClosure != MAP_FAILED), @"mmap failed with error %d.", errno);
		
		//Prep the CIF
		ffi_status status = ffi_prep_cif(mClosureInformation, //inout closure
										 FFI_DEFAULT_ABI, //in ABI
										 (int)[mSignature numberOfArguments], //in numberOfArguments
										 mReturnType, //in returnType
										 mArgumentTypes); //in argumentTypes
		NSAssert((status == FFI_OK), @"ffi_prep_cif failed with error %d.", status);
		
		//Prep the closure
		status = ffi_prep_closure(mClosure, //inout closure
								  mClosureInformation, //in closureInformation
								  &FunctionBridge, //in closureImplementation
								  (__bridge void *)(self)); //in closureImplementationUserInfo
		NSAssert((status == FFI_OK), @"ffi_prep_closure failed with error %d.", status);
		
		//Ensure execution on all platforms
		NSAssert((mprotect(mClosure, sizeof(mClosure), (PROT_READ | PROT_EXEC)) != -1), 
				 @"mprotect failed with error %d.", errno);
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

@synthesize function = mFunction;
@synthesize signature = mSignature;

- (void *)functionPointer
{
	return mClosure;
}

#pragma mark - Identity

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[STNativeFunctionWrapper class]])
		return ([mFunction isEqual:[object function]] && 
				[mSignature isEqual:[object signature]]);
	
	return [super isEqual:object];
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p {%@}>", [self className], self, [mFunction prettyDescription]];
}

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"`Native Function Wrapper for {%@}`", [mFunction prettyDescription]];
}

#pragma mark - Implementing STFunction

- (STScope *)superscope
{
	return [mFunction superscope];
}

- (BOOL)evaluatesOwnArguments
{
	return [mFunction evaluatesOwnArguments];
}

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)scope
{
	return [mFunction applyWithArguments:arguments inScope:scope];
}

@end
