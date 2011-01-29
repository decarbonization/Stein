//
//  STList.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STList.h"
#import "NSObject+SteinTools.h"
#import <stdarg.h>

@implementation STList

#pragma mark Creation

- (id)init
{
	if((self = [super init]))
	{
		mContents = [NSMutableArray new];
		
		return self;
	}
	return nil;
}

+ (STList *)list
{
	return [[self new] autorelease];
}

#pragma mark -

- (id)initWithArray:(NSArray *)array
{
	NSParameterAssert(array);
	
	if((self = [self init]))
	{
		[mContents setArray:array];
		
		return self;
	}
	return nil;
}

+ (STList *)listWithArray:(NSArray *)array
{
	return [[[self alloc] initWithArray:array] autorelease];
}

#pragma mark -

- (id)initWithList:(STList *)list
{
	NSParameterAssert(list);
	
	if((self = [self init]))
	{
		mFlags = list->mFlags;
		mCreationLocation = list ->mCreationLocation;
		[mContents setArray:list->mContents];
		
		return self;
	}
	return nil;
}

+ (STList *)listWithList:(STList *)list
{
	return [[[self alloc] initWithList:list] autorelease];
}

#pragma mark -

- (id)initWithObject:(id)object
{
	if((self = [self init]))
	{
		[mContents addObject:object];
		return self;
	}
	return nil;
}

+ (STList *)listWithObject:(id)object
{
	return [[[self alloc] initWithObject:object] autorelease];
}

- (id)initWithObjects:(id)object fromVaList:(va_list)list
{
	if((self = [self init]))
	{
		if(object)
		{
			[mContents addObject:object];
			
			id value = nil;
			while ((value = va_arg(list, id)) != nil)
				[mContents addObject:value];
		}
	}
	
	return self;
}

- (id)initWithObjects:(id)object, ...
{
	va_list arguments;
	va_start(arguments, object);
	self = [self initWithObjects:object fromVaList:arguments];
	va_end(arguments);
	
	return self;
}

+ (id)listWithObjects:(id)object, ...
{
	va_list arguments;
	va_start(arguments, object);
	STList *list = [[self alloc] initWithObjects:object fromVaList:arguments];
	va_end(arguments);
	
	return list;
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithList:self];
}

#pragma mark -
#pragma mark Coding

- (id)initWithCoder:(NSCoder *)decoder
{
	NSAssert([decoder allowsKeyedCoding], @"Non-keyed coder (%@) given to -[STList initWithCoder:].", decoder);
	
	if((self = [self init]))
	{
		mContents = [[decoder decodeObjectForKey:@"mContents"] retain];
		mFlags = [decoder decodeIntegerForKey:@"mFlags"];
		
		return self;
	}
	return nil;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	NSAssert([encoder allowsKeyedCoding], @"Non-keyed coder (%@) given to -[STList encodeWithCoder:].", encoder);
	
	[encoder encodeObject:mContents forKey:@"mContents"];
	[encoder encodeInteger:mFlags forKey:@"mFlags"];
}

#pragma mark -
#pragma mark Accessing Objects

- (id)head
{
	return ([mContents count] > 0)? [mContents objectAtIndex:0] : nil;
}

- (STList *)tail
{
	return ([mContents count] > 1)? [self sublistWithRange:NSMakeRange(1, [mContents count] - 1)] : [STList list];
}

#pragma mark -

- (id)objectAtIndex:(NSUInteger)index
{
	return [mContents objectAtIndex:index];
}

- (STList *)sublistWithRange:(NSRange)range
{
	STList *sublist = [[[STList alloc] initWithArray:[mContents subarrayWithRange:range]] autorelease];
	
	sublist.creationLocation = mCreationLocation;
	sublist.flags = mFlags;
	
	return sublist;
}

- (STList *)sublistFromIndex:(NSUInteger)index
{
	NSAssert((index < [self count]), 
			 @"Index %ld beyond bounds {0, %ld}", index, [self count]);
	
	return [self sublistWithRange:NSMakeRange(index, [self count] - index)];
}

#pragma mark -
#pragma mark Modification

- (void)addObject:(id)object
{
	[mContents addObject:object];
}

- (void)addObjectsFromArray:(NSArray *)array
{
	[mContents addObjectsFromArray:array];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
	[mContents insertObject:object atIndex:index];
}

#pragma mark -

- (void)removeObject:(id)object
{
	[mContents removeObject:object];
}

- (void)removeObjectsInArray:(NSArray *)array
{
	[mContents removeObjectsInArray:array];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
	[mContents removeObjectAtIndex:index];
}

#pragma mark -

- (void)replaceValuesByPerformingSelectorOnEachObject:(SEL)selector
{
	NSParameterAssert(selector);
	
	for (NSInteger index = (self.count - 1); index >= 0; index--)
		[mContents replaceObjectAtIndex:index withObject:[[mContents objectAtIndex:index] performSelector:selector]];
}

#pragma mark -
#pragma mark Finding Objects

- (NSUInteger)indexOfObject:(id)object
{
	return [mContents indexOfObject:object];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)object
{
	return [mContents indexOfObjectIdenticalTo:object];
}

#pragma mark -
#pragma mark Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[STList class]])
		return [mContents isEqualToArray:((STList *)object)->mContents];
	else if([object isKindOfClass:[NSArray class]])
		return [mContents isEqualToArray:object];
	
	return [super isEqualTo:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@#%p %@(%@)>", [self className], self, ST_FLAG_IS_SET(mFlags, kSTListFlagIsQuoted)? @"'" : @"", [mContents componentsJoinedByString:@" "]];
}

- (NSString *)prettyDescription
{
	//Format: (print "hello, world")
	NSMutableString *description = [NSMutableString string];
	
	//Add the leading quote if we're a quoted string.
	if(ST_FLAG_IS_SET(mFlags, kSTListFlagIsQuoted))
		[description appendString:@"'"];
	
	
	//Open the expression
	if(ST_FLAG_IS_SET(mFlags, kSTListFlagIsDefinition))
		[description appendString:@"{"];
	else
		[description appendString:@"("];
	
	
	//Get the pretty description for each element in our contents
	for (id expression in mContents)
		[description appendFormat:@"%@ ", [expression prettyDescription]];
	
	
	//Remove the trailing space if we're non-empty
	if([mContents count] > 0)
		[description deleteCharactersInRange:NSMakeRange([description length] - 1, 1)];
	
	
	//Close the expression
	if(ST_FLAG_IS_SET(mFlags, kSTListFlagIsDefinition))
		[description appendString:@"}"];
	else
		[description appendString:@")"];
	
	return description;
}

#pragma mark -
#pragma mark Properties

@synthesize flags = mFlags;
@synthesize creationLocation = mCreationLocation;

#pragma mark -

- (NSUInteger)count
{
	return [mContents count];
}

- (NSArray *)allObjects
{
	return [NSArray arrayWithArray:mContents];
}

#pragma mark -
#pragma mark Operators

- (STList *)operatorAdd:(STList *)rightOperand
{
	STList *list = [STList list];
	[list addObjectsFromArray:mContents];
	[list addObjectsFromArray:[rightOperand allObjects]];
	return list;
}

- (STList *)operatorSubtract:(STList *)rightOperand
{
	STList *list = [self copy];
	[list removeObjectsInArray:[rightOperand allObjects]];
	return list;
}

#pragma mark -
#pragma mark Enumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [mContents countByEnumeratingWithState:state objects:stackbuf count:len];
}

#pragma mark -

- (id)foreach:(id < STFunction >)function
{
	for (id object in self)
	{
		@try
		{
			STFunctionApply(function, [STList listWithObject:object]);
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return self;
}

- (id)map:(id < STFunction >)function
{
	STList *mappedObjects = [STList list];
	
	for (id object in self)
	{
		@try
		{
			id mappedObject = STFunctionApply(function, [STList listWithObject:object]);
			if(!mappedObject)
				continue;
			
			[mappedObjects addObject:mappedObject];
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return mappedObjects;
}

- (id)filter:(id < STFunction >)function
{
	STList *filteredObjects = [STList list];
	
	for (id object in self)
	{
		@try
		{
			if(STIsTrue(STFunctionApply(function, [STList listWithObject:object])))
				[filteredObjects addObject:object];
		}
		@catch (STBreakException *e)
		{
			break;
		}
		@catch (STContinueException *e)
		{
			continue;
		}
	}
	
	return filteredObjects;
}

@end
