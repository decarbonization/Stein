//
//  STScope.m
//  stein
//
//  Created by Peter MacWhinnie on 6/4/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STScope.h"

#pragma mark STScopeNode

/*!
 @abstract	The STScopeNode type provides the backing for the STScope object
			in the form of a doubly linked list that stores keys and values.
 @param		previous	The previous node in the list. Readwrite.
 @param		next		The next node in the list. Readwrite.
 @param		key			The key of the node. Readonly.
 @param		value		The value of the node. Readwrite.
 */
struct STScopeNode {
//private:
	volatile STScopeNodeRef previous;
	volatile STScopeNodeRef next;
	NSString *const key;
	volatile id value;
};

#pragma mark Properties

static void STScopeNode_setPrevious(STScopeNodeRef me, STScopeNodeRef previous)
{
	assert(me != NULL);
	
	while (OSAtomicCompareAndSwapPtrBarrier(me->previous, previous, (void *volatile *)&me->previous) == false);
}

static STScopeNodeRef STScopeNode_getPrevious(STScopeNodeRef me)
{
	if(!me)
		return NULL;
	
	OSMemoryBarrier();
	return me->previous;
}

static void STScopeNode_setNext(STScopeNodeRef me, STScopeNodeRef next)
{
	assert(me != NULL);
	
	while (OSAtomicCompareAndSwapPtrBarrier(me->next, next, (void *volatile *)&me->next) == false);
}

static STScopeNodeRef STScopeNode_getNext(STScopeNodeRef me)
{
	if(!me)
		return NULL;
	
	OSMemoryBarrier();
	return me->next;
}

#pragma mark -

static NSString *STScopeNode_getKey(STScopeNodeRef me)
{
	if(!me)
		return nil;
	
	return me->key;
}

#pragma mark -

static void STScopeNode_setValue(STScopeNodeRef me, id value)
{
	assert(me != NULL);
	
	while (OSAtomicCompareAndSwapPtrBarrier(me->value, value, (void *volatile *)&me->value) == false);
}

static id STScopeNode_getValue(STScopeNodeRef me)
{
	if(!me)
		return nil;
	
	OSMemoryBarrier();
	return me->value;
}

#pragma mark -
#pragma mark Creation

static STScopeNodeRef STScopeNode_new(STScopeNodeRef previous, STScopeNodeRef next, NSString *key, id value)
{
	STScopeNodeRef entry = NSAllocateCollectable(sizeof(struct STScopeNode), NSScannedOption);
	*entry = (struct STScopeNode){
		.previous = previous, 
		.next = next, 
		.key = key, 
		.value = value, 
	};
	
	return entry;
}

#pragma mark -
#pragma mark Enumeration

static void STScopeNode_foreach(STScopeNodeRef me, void(^callback)(STScopeNodeRef node, NSString *key, id value, BOOL *stop))
{
	if(!me)
		return;
	
	BOOL stop = NO;
	for (STScopeNodeRef node = me; node != NULL; node = node->next)
	{
		callback(node, node->key, STScopeNode_getValue(node), &stop);
		if(stop)
			break;
	}
}

#pragma mark -
#pragma mark Equality

static BOOL STScopeNode_equals(STScopeNodeRef me, STScopeNodeRef other)
{
	if((me == NULL && other != NULL) || (me != NULL && other == NULL))
		return NO;
	
	return ([me->key isEqualToString:other->key] && 
			[STScopeNode_getValue(me) isEqualTo:STScopeNode_getValue(other)]);
}

#pragma mark -

@implementation STScope

#pragma mark Scope Chaining

@synthesize parentScope = mParentScope;

#pragma mark -
#pragma mark Identity

- (NSString *)description
{
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p {\n", [self className], self];
	
	STScopeNode_foreach(mHead, ^(STScopeNodeRef node, NSString *key, id value, BOOL *stop) {
		[description appendFormat:@"\t%@: %@\n", [key description], [value description]];
	});
	
	[description appendString:@"}>"];
	return description;
}

#pragma mark -

- (NSUInteger)hash
{
	//TODO: This is weak.
	if(!mHead && !mLast)
		return (NSUInteger)([STScope class]);
	
	return ((NSUInteger)(mHead) >> 1) + ((NSUInteger)(mLast) >> 1);
}

#pragma mark -

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[STScope class]])
		return [self isEqualToScope:object];
	
	return [super isEqual:object];
}

- (BOOL)isEqualTo:(id)object
{
	return [self isEqual:object];
}

- (BOOL)isEqualToScope:(STScope *)scope
{
	//TODO: This is inefficient.
	if(self == scope)
		return YES;
	
	STScopeNodeRef leftNode = NULL, rightNode = NULL;
	while (leftNode && rightNode)
	{
		if(!STScopeNode_equals(leftNode, rightNode))
			return NO;
		
		leftNode = leftNode->next;
		rightNode = rightNode->next;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Variables

- (STScopeNodeRef)firstNodeWithKey:(NSString *)name
{
	__block STScopeNodeRef firstMatchingNode = NULL;
	STScopeNode_foreach(mHead, ^(STScopeNodeRef node, NSString *key, id value, BOOL *stop) {
		if([key isEqualToString:name])
		{
			firstMatchingNode = node;
			*stop = YES;
		}
	});
	
	return firstMatchingNode;
}

#pragma mark -

- (void)setValue:(id)value forVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes
{
	NSParameterAssert(value);
	NSParameterAssert(name);
	
	[self willChangeValueForKey:name];
	
	STScopeNodeRef matchingNode = [self firstNodeWithKey:name];
	if(matchingNode)
	{
		STScopeNode_setValue(matchingNode, value);
	}
	else
	{
		if(searchParentScopes)
		{
			STScope *parentScope = self.parentScope;
			do {
				matchingNode = [parentScope firstNodeWithKey:name];
				if(matchingNode)
				{
					STScopeNode_setValue(matchingNode, value);
					return;
				}
				
				parentScope = parentScope.parentScope;
			} while (parentScope != nil);
		}
		
		STScopeNodeRef newNode = STScopeNode_new(mLast, nil, name, value);
		if(mLast)
			STScopeNode_setNext(mLast, newNode);
		
		mLast = newNode;
		if(!mHead)
			mHead = newNode;
	}
	
	[self didChangeValueForKey:name];
}

- (void)removeValueForVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes
{
	NSParameterAssert(name);
	
	[self willChangeValueForKey:name];
	
	STScopeNodeRef matchingNode = [self firstNodeWithKey:name];
	if(matchingNode)
	{
		STScopeNodeRef previousNode = STScopeNode_getPrevious(matchingNode);
		STScopeNodeRef nextNode = STScopeNode_getPrevious(matchingNode);
		
		if(nextNode)
			STScopeNode_setPrevious(nextNode, previousNode);
		
		if(previousNode)
			STScopeNode_setNext(previousNode, nextNode);
		
		if(mHead == matchingNode)
			mHead = NULL;
		
		if(mLast == matchingNode)
			mLast = previousNode;
	}
	else
	{
		if(searchParentScopes)
			[mParentScope removeValueForVariableNamed:name searchParentScopes:searchParentScopes];
	}
	
	[self didChangeValueForKey:name];
}

- (id)valueForVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes
{
	NSParameterAssert(name);
	
	id value = STScopeNode_getValue([self firstNodeWithKey:name]);
	if(!value && searchParentScopes)
	{
		return [mParentScope valueForVariableNamed:name searchParentScopes:searchParentScopes];
	}
	
	return value;
}

#pragma mark -
#pragma mark KVC

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	[self setValue:value forVariableNamed:key searchParentScopes:YES];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [self valueForVariableNamed:key searchParentScopes:YES];
}

@end
