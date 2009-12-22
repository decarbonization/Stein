//
//  STList.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STList.h"
#import "NSObject+Stein.h"

@implementation STList

#pragma mark Destruction

- (void)dealloc
{
	[mContents release];
	mContents = nil;
	
	[super dealloc];
}

#pragma mark -
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
		mEvaluator = list->mEvaluator;
		mIsQuoted = list->mIsQuoted;
		mIsDoConstruct = list->mIsDoConstruct;
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

#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithList:self];
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
	sublist.evaluator = mEvaluator;
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

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
	[mContents insertObject:object atIndex:index];
}

#pragma mark -

- (void)removeObject:(id)object
{
	[mContents removeObject:object];
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
	return [NSString stringWithFormat:@"<%@#%p %@(%@)>", [self className], self, mIsQuoted? @"'" : @"", [mContents componentsJoinedByString:@" "]];
}

- (NSString *)prettyDescription
{
	//Format: (print "hello, world")
	NSMutableString *description = [NSMutableString string];
	
	//Add the leading quote if we're a quoted string.
	if(mIsQuoted)
		[description appendString:@"'"];
	
	
	//Open the expression
	[description appendString:mIsDoConstruct? @"[" : @"("];
	
	
	//Get the pretty description for each element in our contents
	for (id expression in mContents)
		[description appendFormat:@"%@ ", [expression prettyDescription]];
	
	
	//Remove the trailing space if we're non-empty
	if([mContents count] > 0)
		[description deleteCharactersInRange:NSMakeRange([description length] - 1, 1)];
	
	
	//Close the expression
	[description appendString:mIsDoConstruct? @"]" : @")"];
	
	return description;
}

#pragma mark -
#pragma mark Properties

@synthesize isQuoted = mIsQuoted;
@synthesize isDoConstruct = mIsDoConstruct;
@synthesize evaluator = mEvaluator;

#pragma mark -

@dynamic count;
- (NSUInteger)count
{
	return [mContents count];
}

@dynamic allObjects;
- (NSArray *)allObjects
{
	return [NSArray arrayWithArray:mContents];
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
			if([STFunctionApply(function, [STList listWithObject:object]) isTrue])
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
