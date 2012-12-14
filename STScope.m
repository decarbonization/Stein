//
//  STScope.m
//  stein
//
//  Created by Peter MacWhinnie on 6/4/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STScope.h"

///The STScopeNode class is a linked list of key-value pairs
///used to implement the thread-safe STScope storage class.
@interface STScopeNode : NSObject
{
    NSString *_key;
    BOOL _readonly;
}

///Initialized the receiver with a given key and whether or not it is readonly.
///
/// \param  key         The key. Required.
/// \param  readonly    Whether or not the node is readonly.
///
/// \param A fully initialized scope node.
- (id)initWithKey:(NSString *)key readonly:(BOOL)readonly;

#pragma mark - Properties

///The previous scope node in the chain.
@property (weak) STScopeNode *previous;

///The next scope node in the chain.
@property STScopeNode *next;

///The key of the scope node.
@property (readonly, copy) NSString *key;

///Whether or not the scope node is readonly.
@property (readonly) BOOL readonly;

///The value of the scope node.
@property id value;

#pragma mark - Identity

///Returns a boolean indicating whether or not the receiver is equal to another scope node.
- (BOOL)isEqualToScopeNode:(STScopeNode *)otherScopeNode;

// \inherit
- (NSUInteger)hash;

@end

@implementation STScopeNode

- (id)initWithKey:(NSString *)key readonly:(BOOL)readonly
{
    NSParameterAssert(key);
    
    if((self = [super init]))
    {
        _key = [key copy];
        _readonly = readonly;
    }
    
    return self;
}

#pragma mark - Properties

@synthesize key = _key;
@synthesize readonly = _readonly;

#pragma mark - Identity

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[STScopeNode class]])
        return [self isEqualToScopeNode:object];
    
    return NO;
}

- (BOOL)isEqualToScopeNode:(STScopeNode *)otherScopeNode
{
    return ([self.key isEqualToString:otherScopeNode.key] &&
			[self.value isEqual:otherScopeNode.value]);
}

- (NSUInteger)hash
{
    return ((NSUInteger)(self) >> 1);
}

@end

#pragma mark - Enumeration

///Iterate a chain of STScopeNode values.
///
/// \param	me			The node to iterate. Optional.
/// \param	callback	The block to invoke for each value in the node chain. Optional.
static void EnumerateScopeNodeChain(STScopeNode *me, void(^callback)(STScopeNode *node, NSString *key, id value, BOOL *stop))
{
	if(!me || !callback)
		return;
	
	BOOL stop = NO;
	for (STScopeNode *node = me; node != nil; node = node.next)
	{
		callback(node, node.key, node.value, &stop);
		if(stop)
			break;
	}
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

#pragma mark - Scope Chaining

- (void)setParentScope:(STScope *)parentScope
{
	@synchronized(self)
	{
		mParentScope = parentScope;
		mModule = parentScope.module;
	}
}

- (STScope *)parentScope
{
	@synchronized(self)
	{
		return mParentScope;
	}
}

#pragma mark - Identity

- (NSString *)description
{
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p %@ {\n", [self className], self, mName ?: @"(anonymous scope)"];
	
	EnumerateScopeNodeChain(mHead, ^(STScopeNode *node, NSString *key, id value, BOOL *stop) {
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
	
	return [mHead hash] + [mLast hash];
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
	
	STScopeNode *leftNode = nil, *rightNode = nil;
	while (leftNode && rightNode)
	{
		if(![leftNode isEqualToScopeNode:rightNode])
			return NO;
		
		leftNode = leftNode.next;
		rightNode = rightNode.next;
	}
	
	return YES;
}

#pragma mark - Variables

- (STScopeNode *)firstNodeWithKey:(NSString *)name
{
	__block STScopeNode *firstMatchingNode = nil;
	EnumerateScopeNodeChain(mHead, ^(STScopeNode *node, NSString *key, id value, BOOL *stop) {
		if([key isEqualToString:name])
		{
			firstMatchingNode = node;
			*stop = YES;
		}
	});
	
	return firstMatchingNode;
}

#pragma mark -

- (void)setValuesForVariablesInScope:(STScope *)scope
{
	NSParameterAssert(scope);
	
	EnumerateScopeNodeChain(scope->mHead, ^(STScopeNode *node, NSString *key, id value, BOOL *stop) {
		if(node.readonly)
			[self setValue:value forConstantNamed:key];
		else
			[self setValue:value forVariableNamed:key searchParentScopes:YES];
	});
}

- (void)setValue:(id)value forVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes
{
	NSParameterAssert(value);
	NSParameterAssert(name);
	
	[self willChangeValueForKey:name];
	
	STScopeNode *matchingNode = [self firstNodeWithKey:name];
	if(matchingNode)
	{
		NSAssert(!matchingNode.readonly, @"Attempting to set readonly variable %@.", name);
		matchingNode.value = value;
	}
	else
	{
		if(searchParentScopes)
		{
			STScope *parentScope = self.parentScope;
			do {
				matchingNode = [parentScope firstNodeWithKey:name];
				if(matchingNode && !matchingNode.readonly)
				{
					matchingNode.value = value;
					return;
				}
				
				parentScope = parentScope.parentScope;
			} while (parentScope != nil);
		}
		
        STScopeNode *newNode = [[STScopeNode alloc] initWithKey:name readonly:NO];
		newNode.value = value;
        newNode.previous = mLast;
		if(mLast)
			mLast.next = newNode;
		
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
	
	STScopeNode *matchingNode = [self firstNodeWithKey:name];
	if(matchingNode)
	{
		NSAssert(!matchingNode.readonly, @"Attempting to set readonly variable %@.", name);
		matchingNode.value = value;
	}
	else
	{
		STScopeNode *newNode = [[STScopeNode alloc] initWithKey:name readonly:NO];
		newNode.value = value;
        newNode.previous = mLast;
		if(mLast)
			mLast.next = newNode;
		
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
	
	STScopeNode *matchingNode = [self firstNodeWithKey:name];
	if(matchingNode)
	{
		STScopeNode *previousNode = matchingNode.previous;
		STScopeNode *nextNode = matchingNode.next;
		
		if(nextNode)
			nextNode.previous = previousNode;
		
		if(previousNode)
			previousNode.next = nextNode;
		
		if(mHead == matchingNode)
			mHead = nil;
		
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
	
	id value = [self firstNodeWithKey:name].value;
	if(!value && searchParentScopes)
	{
		return [mParentScope valueForVariableNamed:name searchParentScopes:searchParentScopes];
	}
	
	return value;
}

#pragma mark -

- (NSArray *)allVariableNames
{
	NSMutableArray *names = [NSMutableArray array];
	EnumerateScopeNodeChain(mHead, ^(STScopeNode *node, NSString *key, id value, BOOL *stop) {
		[names addObject:key];
	});
	
	return names;
}

- (NSArray *)allVariableValues
{
	NSMutableArray *values = [NSMutableArray array];
	EnumerateScopeNodeChain(mHead, ^(STScopeNode *node, NSString *key, id value, BOOL *stop) {
		[values addObject:value];
	});
	
	return values;
}

- (void)enumerateNamesAndValuesUsingBlock:(void (^)(NSString *name, id value, BOOL *stop))block
{
	if(!block)
		return;
	
	EnumerateScopeNodeChain(mHead, ^(STScopeNode *node, NSString *key, id value, BOOL *stop) {
		block(key, value, stop);
	});
}

#pragma mark - KVC

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	[self setValue:value forVariableNamed:key searchParentScopes:YES];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [self valueForVariableNamed:key searchParentScopes:YES];
}

#pragma mark - Properties

@synthesize name = mName;
@synthesize module = mModule;

@end
