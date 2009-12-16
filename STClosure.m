//
//  STClosure.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STClosure.h"
#import "STEvaluator.h"
#import "STList.h"
#import "STTypeBridge.h"
#import <sys/mman.h>

ST_EXTERN ffi_type *STTypeBridgeConvertObjCTypeToFFIType(const char *objcType); //from STTypeBridge.m

#pragma mark -

@implementation STClosure

#pragma mark Destruction

- (void)dealloc
{
	if(munmap(mFFIClosure, sizeof(mFFIClosure)) == -1)
	{
		NSLog(@"uh oh, munmap failed with error %d", errno);
	}
	
	if(mFFIClosureInformation)
	{
		free(mFFIClosureInformation);
		mFFIClosureInformation = NULL;
	}
	
	if(mFFIArgumentTypes)
	{
		free(mFFIArgumentTypes);
		mFFIArgumentTypes = NULL;
	}
	
	[mClosureSignature release];
	mClosureSignature = nil;
	
	[mPrototype release];
	mPrototype = nil;
	
	[mImplementation release];
	mImplementation = nil;
	
	[mSuperscope release];
	mSuperscope = nil;
	
	[super dealloc];
}

- (void)finalize
{
	if(munmap(mFFIClosure, sizeof(mFFIClosure)) == -1)
	{
		NSLog(@"uh oh, munmap failed with error %d", errno);
	}
	
	[super finalize];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithPrototype:(STList *)prototype forImplementation:(STList *)implementation withSignature:(NSMethodSignature *)signature fromEvaluator:(STEvaluator *)evaluator inScope:(NSMutableDictionary *)superscope
{
	if((self = [super init]))
	{
		mPrototype = [prototype retain];
		mImplementation = [implementation retain];
		mClosureSignature = [signature retain];
		mEvaluator = evaluator;
		mSuperscope = [superscope retain];
		
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Stein Function

- (BOOL)evaluatesOwnArguments
{
	return NO;
}

- (id)applyWithArguments:(STList *)arguments inScope:(NSMutableDictionary *)superscope
{
	NSMutableDictionary *scope = [mEvaluator scopeWithEnclosingScope:superscope];
	NSUInteger index = 0;
	for (id name in mPrototype)
		[scope setObject:[arguments objectAtIndex:index++] forKey:name];
	
	return [mEvaluator evaluateExpression:mImplementation inScope:scope];
}

#pragma mark -
#pragma mark Native Function

/*!
 @function
 @abstract	This function serves as the bridge between libFFI and STClosure.
 */
static void FunctionBridge(ffi_cif *clossureInformation, void *returnBuffer, void **arguments, void *userData)
{
	STClosure *self = (STClosure *)userData;
	STEvaluator *evaluator = self->mEvaluator;
	
	STList *argumentsAsObjects = [[STList new] autorelease];
	NSUInteger numberOfArguments = [self->mClosureSignature numberOfArguments];
	for (NSUInteger index = 0; index < numberOfArguments; index++)
		[argumentsAsObjects addObject:STTypeBridgeConvertValueOfTypeIntoObject(arguments[index], [self->mClosureSignature getArgumentTypeAtIndex:index])];
	
	id resultObject = [self applyWithArguments:argumentsAsObjects inScope:self->mSuperscope];
	STTypeBridgeConvertObjectIntoType(resultObject, [self->mClosureSignature methodReturnType], returnBuffer);
}

@dynamic functionPointer;
- (void *)functionPointer
{
	//Creation of the libffi closure is deferred
	//until it is actually needed. This way we
	//don't waste resources when we don't have to.
	if(!mFFIArgumentTypes)
	{
		NSUInteger numberOfArguments = [mClosureSignature numberOfArguments];
		
		//Resolve the argument types
		mFFIArgumentTypes = NSAllocateCollectable((sizeof(ffi_type *) * numberOfArguments), 0);
		
		for (NSUInteger index = 0; index < numberOfArguments; index++)
			mFFIArgumentTypes[index] = STTypeBridgeConvertObjCTypeToFFIType([mClosureSignature getArgumentTypeAtIndex:index]);
		
		mFFIReturnType = STTypeBridgeConvertObjCTypeToFFIType([mClosureSignature methodReturnType]);
		
		//Create the closure
		mFFIClosureInformation = NSAllocateCollectable(sizeof(ffi_cif), 0);
		
		if((mFFIClosure = mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE,
							   MAP_ANON | MAP_PRIVATE, -1, 0)) == MAP_FAILED)
		{
			[NSException raise:NSInternalInconsistencyException format:@"mmap failed with error %d.", errno];
		}
		
		//Prep the CIF
		if(ffi_prep_cif(mFFIClosureInformation, FFI_DEFAULT_ABI, (int)[mClosureSignature numberOfArguments], mFFIReturnType, mFFIArgumentTypes) != FFI_OK)
		{
			[NSException raise:NSInternalInconsistencyException format:@"ffi_prep_cif failed with error."];
		}
		
		//Prep the closure
		if(ffi_prep_closure(mFFIClosure, mFFIClosureInformation, &FunctionBridge, self) != FFI_OK)
		{
			[NSException raise:NSInternalInconsistencyException format:@"ffi_prep_closure failed with error."];
		}
		
		//Ensure execution on all platforms
		if(mprotect(mFFIClosure, sizeof(mFFIClosure), PROT_READ | PROT_EXEC) == -1)
		{
			[NSException raise:NSInternalInconsistencyException format:@"mprotect failed with error %d.", errno];
		}
	}
	
	return mFFIClosure;
}

#pragma mark -
#pragma mark Properties

@synthesize evaluator = mEvaluator;
@synthesize superscope = mSuperscope;

#pragma mark -

@synthesize closureSignature = mClosureSignature;
@synthesize prototype = mPrototype;
@synthesize implementation = mImplementation;

#pragma mark -
#pragma mark Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[STClosure class]])
	{
		return ([self.prototype isEqualTo:[object prototype]] && 
				[self.implementation isEqualTo:[object implementation]] && 
				[self.closureSignature isEqualTo:[object closureSignature]]);
	}
	
	return [super isEqualTo:object];
}

@end
