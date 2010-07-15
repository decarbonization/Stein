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
 @field		previous	The previous node in the list. Readwrite.
 @field		next		The next node in the list. Readwrite.
 @field		key			The key of the node. Readonly.
 @param		readonly	Whether or not the value of the node is readonly. Readonly.
 @field		value		The value of the node. Readwrite.
 */
struct STScopeNode {
//private:
	volatile STScopeNodeRef previous;
	volatile STScopeNodeRef next;
	NSString *const key;
	BOOL const readonly;
	volatile id value;
};

#pragma mark Properties

/*!
 @abstract	Set the previous node of a STScopeNode.
 @param		me			The node to modify. Required.
 @param		previous	The new previous. Optional.
 */
static void STScopeNode_setPrevious(STScopeNodeRef me, STScopeNodeRef previous)
{
	assert(me != NULL);
	
	OSAtomicCompareAndSwapPtrBarrier(me->previous, previous, (void *volatile *)&me->previous);
}

/*!
 @abstract	Get the previous node of a STScopeNode.
 @param		me	The node to read from. Optional.
 */
static STScopeNodeRef STScopeNode_getPrevious(STScopeNodeRef me)
{
	if(!me)
		return NULL;
	
	OSMemoryBarrier();
	return me->previous;
}

/*!
 @abstract	Set the next node of a STScopeNode.
 @param		me		The node to modify. Required.
 @param		next	The new next. Optional.
 */
static void STScopeNode_setNext(STScopeNodeRef me, STScopeNodeRef next)
{
	assert(me != NULL);
	
	OSAtomicCompareAndSwapPtrBarrier(me->next, next, (void *volatile *)&me->next);
}

/*!
 @abstract	Get the next node of a STScopeNode.
 @param		me	The node to read from. Optional.
 */
static STScopeNodeRef STScopeNode_getNext(STScopeNodeRef me)
{
	if(!me)
		return NULL;
	
	OSMemoryBarrier();
	return me->next;
}

#pragma mark -

/*!
 @abstract	Get the key of a STScopeNode.
 @param		me	The node to read from. Optional.
 */
static NSString *STScopeNode_getKey(STScopeNodeRef me)
{
	if(!me)
		return nil;
	
	return me->key;
}

static BOOL STScopeNode_getReadonly(STScopeNodeRef me)
{
	if(!me)
		return YES;
	
	return me->readonly;
}

#pragma mark -

/*!
 @abstract	Set the value of a STScopeNode.
 @param		me		The node to modify. Required.
 @param		value	The value. Optional.
 */
static void STScopeNode_setValue(STScopeNodeRef me, id value)
{
	assert(me != NULL);
	
	NSCAssert(!me->readonly, @"Attempting to write to readonly scope node %@", me->key);
	OSAtomicCompareAndSwapPtrBarrier(me->value, value, (void *volatile *)&me->value);
}

/*!
 @abstract	Get the value of a STScopeNode.
 @param		me	The node to read from. Optional.
 */
static id STScopeNode_getValue(STScopeNodeRef me)
{
	if(!me)
		return nil;
	
	OSMemoryBarrier();
	return me->value;
}

#pragma mark -
#pragma mark Creation

/*!
 @abstract	Creates and returns a new STScopeNode value.
 @param		previous	The node that precedes the node being created in a chain. Optional.
 @param		next		The node that succeeds the node being created in a chain. Optional.
 @param		key			The key of the node. Required.
 @param		readonly	Whether or not the value of the node is readonly.
 @param		value		The value of the node. Optional.
 @result	A pointer to an STScopeNode struct whose lifecycle is managed by the garbage collector.
 */
static STScopeNodeRef STScopeNode_new(STScopeNodeRef previous, STScopeNodeRef next, NSString *key, BOOL readonly, id value)
{
	assert(key != nil);
	
	STScopeNodeRef entry = NSAllocateCollectable(sizeof(struct STScopeNode), NSScannedOption);
	*entry = (struct STScopeNode){
		.previous = previous, 
		.next = next, 
		.key = key, 
		.readonly = readonly, 
		.value = value, 
	};
	
	return entry;
}

#pragma mark -
#pragma mark Enumeration

/*!
 @abstract	Iterate a chain of STScopeNode values.
 @param		me			The node to iterate. Optional.
 @param		callback	The block to invoke for each value in the node chain. Optional.
 */
static void STScopeNode_foreach(STScopeNodeRef me, void(^callback)(STScopeNodeRef node, NSString *key, id value, BOOL *stop))
{
	if(!me || !callback)
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

/*!
 @abstract	Returns whether or not two STScopeNodes are equal to each other.
 */
static BOOL STScopeNode_equals(STScopeNodeRef me, STScopeNodeRef other)
{
	if((me == NULL && other != NULL) || (me != NULL && other == NULL))
		return NO;
	
	return ([me->key isEqualToString:other->key] && 
			[STScopeNode_getValue(me) isEqualTo:STScopeNode_getValue(other)]);
}

/*!
 @abstract	Returns a (weak) hash for a STScopeNode.
 */
static NSUInteger STScopeNode_hash(STScopeNodeRef me)
{
	if(!me)
		return 0;
	
	return ((NSUInteger)(me) >> 1);
}

#pragma mark -

@implementation STScope

#pragma mark Initialization

+ (STScope *)scopeWithParentScope:(STScope *)parentScope
{
	return [[self alloc] initWithParentScope:parentScope];
}

- (id)initWithParentScope:(STScope *)parentScope
{
	if((self = [self init]))
	{
		self.parentScope = parentScope;
	}
	
	return self;
}

#pragma mark -
#pragma mark Scope Chaining

@synthesize parentScope = mParentScope;

#pragma mark -
#pragma mark Identity

- (NSString *)description
{
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p %@ {\n", [self className], self, mName ?: @"(anonymous scope)"];
	
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
	
	return STScopeNode_hash(mHead) + STScopeNode_hash(mLast);
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
		NSAssert(!STScopeNode_getReadonly(matchingNode), @"Attempting to set readonly variable %@.", name);
		STScopeNode_setValue(matchingNode, value);
	}
	else
	{
		if(searchParentScopes)
		{
			STScope *parentScope = self.parentScope;
			do {
				matchingNode = [parentScope firstNodeWithKey:name];
				if(matchingNode && !STScopeNode_getReadonly(matchingNode))
				{
					STScopeNode_setValue(matchingNode, value);
					return;
				}
				
				parentScope = parentScope.parentScope;
			} while (parentScope != nil);
		}
		
		STScopeNodeRef newNode = STScopeNode_new(mLast, nil, name, NO, value);
		if(mLast)
			STScopeNode_setNext(mLast, newNode);
		
		mLast = newNode;
		if(!mHead)
			mHead = newNode;
	}
	
	[self didChangeValueForKey:name];
}

- (void)setValue:(id)value forConstantNamed:(NSString *)name
{
	NSParameterAssert(value);
	NSParameterAssert(name);
	
	[self willChangeValueForKey:name];
	
	STScopeNodeRef matchingNode = [self firstNodeWithKey:name];
	if(matchingNode)
	{
		NSAssert(!STScopeNode_getReadonly(matchingNode), @"Attempting to set readonly variable %@.", name);
		STScopeNode_setValue(matchingNode, value);
	}
	else
	{
		STScopeNodeRef newNode = STScopeNode_new(mLast, nil, name, YES, value);
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
		STScopeNodeRef nextNode = STScopeNode_getNext(matchingNode);
		
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

#pragma mark -
#pragma mark Properties

@synthesize name = mName;

@end
