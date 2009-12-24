//
//  NSObject+SteinBuiltInDecorators.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/24.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "NSObject+SteinBuiltInDecorators.h"
#import <objc/objc-runtime.h>
#import "NSObject+Stein.h"

#pragma mark Synthesized Accessor/Mutator Implementations

void SynthesizedSet(id self, SEL _cmd, id value)
{
	NSString *fullSelectorString = NSStringFromSelector(_cmd);
	NSString *selectorString = [fullSelectorString substringWithRange:NSMakeRange(3, [fullSelectorString length] - 4)];
	
	NSString *ivarName = [NSString stringWithFormat:@"%C%@", tolower([selectorString characterAtIndex:0]), [selectorString substringFromIndex:1]];
	[self setValue:value forIvarNamed:ivarName];
}

id SynthesizedGet(id self, SEL _cmd)
{
	return [self valueForIvarNamed:NSStringFromSelector(_cmd)];
}

#pragma mark -

@implementation NSObject (SteinBuiltInDecorators)

+ (void)load
{
	static BOOL hasAddedAliases = NO;
	if(!hasAddedAliases)
	{
		//Class identity decorator aliases.
		Method implementsMethod = class_getClassMethod(self, @selector(implements:));
		class_addMethod(self, 
						sel_registerName("implements"), 
						method_getImplementation(implementsMethod), 
						method_getTypeEncoding(implementsMethod));
		
		
		//Property decorator aliases.
		Method synthesizeMethod = class_getClassMethod(self, @selector(synthesize:));
		class_addMethod(self, 
						sel_registerName("synthesize"), 
						method_getImplementation(synthesizeMethod), 
						method_getTypeEncoding(synthesizeMethod));
		
		Method synthesizeReadOnlyMethod = class_getClassMethod(self, @selector(synthesizeReadOnly:));
		class_addMethod(self, 
						sel_registerName("synthesize-readonly"), 
						method_getImplementation(synthesizeReadOnlyMethod), 
						method_getTypeEncoding(synthesizeReadOnlyMethod));
		
		Method synthesizeWriteOnlyMethod = class_getClassMethod(self, @selector(synthesizeWriteOnly:));
		class_addMethod(self, 
						sel_registerName("synthesize-writeonly"), 
						method_getImplementation(synthesizeWriteOnlyMethod), 
						method_getTypeEncoding(synthesizeWriteOnlyMethod));
		
		//IBOutlet is provided as an alias for synthesize-writeonly. This will eventually make Interface Builder support considerably easier.
		class_addMethod(self, 
						sel_registerName("IBOutlet"), 
						method_getImplementation(synthesizeWriteOnlyMethod), 
						method_getTypeEncoding(synthesizeWriteOnlyMethod));
		
		
		hasAddedAliases = YES;
	}
}

#pragma mark -
#pragma mark Conformance

+ (void)implements:(NSObject < NSFastEnumeration > *)protocols
{
	for (id protocolName in protocols)
	{
		Protocol *protocol = NSProtocolFromString([protocolName string]);
		class_addProtocol(self, protocol);
	}
}

#pragma mark -
#pragma mark Properties

+ (void)synthesize:(id)ivarName
{
	NSParameterAssert(ivarName);
	
	//Add the accessor
	NSString *accessorName = [ivarName string];
	class_addMethod(self, NSSelectorFromString(accessorName), (IMP)&SynthesizedGet, "@@:");
	
	//Add the mutator
	NSString *mutatorName = [NSString stringWithFormat:@"set%C%@:", toupper([accessorName characterAtIndex:0]), [accessorName substringFromIndex:1]];
	class_addMethod(self, NSSelectorFromString(mutatorName), (IMP)&SynthesizedSet, "v@:@");
}

+ (void)synthesizeReadOnly:(id)ivarName
{
	NSParameterAssert(ivarName);
	
	//Add the accessor
	NSString *accessorName = [ivarName string];
	class_addMethod(self, NSSelectorFromString(accessorName), (IMP)&SynthesizedGet, "@@:");
}

+ (void)synthesizeWriteOnly:(id)ivarName
{
	NSParameterAssert(ivarName);
	
	//Add the mutator
	NSString *accessorName = [ivarName string];
	NSString *mutatorName = [NSString stringWithFormat:@"set%C%@:", toupper([accessorName characterAtIndex:0]), [accessorName substringFromIndex:1]];
	class_addMethod(self, NSSelectorFromString(mutatorName), (IMP)&SynthesizedSet, "v@:@");
}

@end
