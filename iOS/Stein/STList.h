//
//  STList.h
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STEnumerable.h"

enum STListFlags {
	kSTListFlagsNone = 0,
	kSTListFlagIsQuoted = 1 << 1, 
	kSTListFlagIsDefinition = 1 << 2, 
	kSTListFlagIsDefinitionParameters = 1 << 4,
};
typedef NSUInteger STListFlags;

///The STList class is used to represent s-expressions in the Stein language.
@interface STList : NSObject < STEnumerable, NSFastEnumeration, NSCopying, NSCoding >
{
	NSMutableArray *mContents;
	STListFlags mFlags;
	STCreationLocation *mCreationLocation;
}
#pragma mark Creation

///Initialize the receiver as an empty list.
- (id)init;

#pragma mark -

///Initialize the receiver with a specified array.
///
/// \param	array	The array to initialize the receiver's contents with. May not be nil.
///
/// \result	A list with the contents of the specified array.
- (id)initWithArray:(NSArray *)array;

#pragma mark -

///Initialize the receiver with the contents of a specified list.
///
/// \param		list	The list to initialize the receiver's contents with. May not be nil.
///
/// \result		A list with the contents of the specified list.
///
///The receiver will also take the specified lists evaluator, and quote/do construct status.
- (id)initWithList:(STList *)list;

#pragma mark -

///Initialize the receiver with a specified object.
- (id)initWithObject:(id)object;
///Initializes the receiver with a nil-terminated list of objects.
- (id)initWithObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

#pragma mark - Accessing objects

///Get the head of the list.
///
/// \result	The head of the list; nil if the receiver is empty.
- (id)head;

///Get the tail (everything but the first object) of the list.
///
/// \result	The tail of the list; an empty list of the receiver has less than two elements.
- (STList *)tail;

#pragma mark -

///Look up the object at a specified index in the receiver.
- (id)objectAtIndex:(NSUInteger)index;

///Create a new autoreleased sublist with the contents of the receiver in the specified range.
///
///The list returned by this method inherits the receiver's evaluator, but does not inherit it's quote/do construct status.
- (STList *)sublistWithRange:(NSRange)range;

///Create a new autoreleased sublist with the contents of the receiver from a specified index to the end of the list.
///
///The list returned by this method inherits the receiver's evaluator, but does not inherit it's quote/do construct status.
- (STList *)sublistFromIndex:(NSUInteger)index;

#pragma mark - Modification

///Add an object to the end of the receiver.
- (void)addObject:(id)object;

///Add an array of objects to the receiver.
- (void)addObjectsFromArray:(NSArray *)array;

///Insert an object into the receiver at a specified index.
- (void)insertObject:(id)object atIndex:(NSUInteger)index;

#pragma mark -

///Remove a specified object from the receiver.
- (void)removeObject:(id)object;

///Remove an array of objects from the receiver.
- (void)removeObjectsInArray:(NSArray *)array;

///Remove the object at a specified index from the receiver.
- (void)removeObjectAtIndex:(NSUInteger)index;

#pragma mark -

- (void)replaceValuesByPerformingSelectorOnEachObject:(SEL)selector;

#pragma mark - Finding Objects

///Find the location of a specified object.
- (NSUInteger)indexOfObject:(id)object;

///Find the location of a specified object using a pointer comparison.
- (NSUInteger)indexOfObjectIdenticalTo:(id)object;

#pragma mark - Properties

///Any flags specifying the structure of an STList object.
@property STListFlags flags;

///The location at which the list was created.
@property STCreationLocation *creationLocation;

#pragma mark -

///The number of objects in the list.
@property (readonly) NSUInteger count;

///All of the objects in the list in the form of an array.
@property (readonly) NSArray *allObjects;

@end
