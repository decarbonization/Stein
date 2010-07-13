//
//  STList.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STEnumerable.h>

enum STListFlags {
	kSTListFlagsNone = 0,
	kSTListFlagIsQuoted = 1 << 1, 
	kSTListFlagIsDefinition = 1 << 2, 
	kSTListFlagIsDefinitionParameters = 1 << 4,
};
typedef NSUInteger STListFlags;

/*!
 @class
 @abstract	The STList class is used to represent s-expressions in the Stein language.
 */
@interface STList : NSObject < STEnumerable, NSFastEnumeration, NSCopying, NSCoding >
{
	/* owner */	NSMutableArray *mContents;
	/* n/a */	STListFlags mFlags;
	/* n/a */	STCreationLocation mCreationLocation;
}
#pragma mark Creation

/*!
 @abstract	Initialize the receiver as an empty list.
 */
- (id)init;

/*!
 @abstract	Create a new autoreleased empty list.
 */
+ (STList *)list;

#pragma mark -

/*!
 @abstract	Initialize the receiver with a specified array.
 @param		array	The array to initialize the receiver's contents with. May not be nil.
 @result	A list with the contents of the specified array.
 */
- (id)initWithArray:(NSArray *)array;

/*!
 @abstract	Create a new autoreleased list with a specified array.
 @param		array	The array to use as list's contents. May not be nil.
 @result	A list with the contents of the specified array.
 */
+ (STList *)listWithArray:(NSArray *)array;

#pragma mark -

/*!
 @abstract		Initialize the receiver with the contents of a specified list.
 @param			list	The list to initialize the receiver's contents with. May not be nil.
 @result		A list with the contents of the specified list.
 @discussion	The receiver will also take the specified lists evaluator, and quote/do construct status.
 */
- (id)initWithList:(STList *)list;

/*!
 @abstract		Create a new autoreleased list with the contents of a specified list.
 @param			list	The list to use as the list's contents. May not be nil.
 @result		A list with the contents of the specified list.
 @discussion	The receiver will also take the specified lists evaluator, and quote/do construct status.
 */
+ (STList *)listWithList:(STList *)list;

#pragma mark -

/*!
 @abstract	Initialize the receiver with a specified object.
 */
- (id)initWithObject:(id)object;

/*!
 @abstract	Returns a new STList with a specified object.
 */
+ (STList *)listWithObject:(id)object;

/*!
 @abstract	Initializes the receiver with a nil-terminated list of objects.
 */
- (id)initWithObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

/*!
 @abstract	Creates a new STList with a nil-terminated list of objects.
 */
+ (STList *)listWithObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

#pragma mark -
#pragma mark Accessing objects

/*!
 @abstract	Get the head of the list.
 @result	The head of the list; nil if the receiver is empty.
 */
- (id)head;

/*!
 @abstract	Get the tail (everything but the first object) of the list.
 @result	The tail of the list; an empty list of the receiver has less than two elements.
 */
- (STList *)tail;

#pragma mark -

/*!
 @abstract	Look up the object at a specified index in the receiver.
 */
- (id)objectAtIndex:(NSUInteger)index;

/*!
 @abstract		Create a new autoreleased sublist with the contents of the receiver in the specified range.
 @discussion	The list returned by this method inherits the receiver's evaluator, but does not inherit it's quote/do construct status.
 */
- (STList *)sublistWithRange:(NSRange)range;

/*!
 @abstract		Create a new autoreleased sublist with the contents of the receiver from a specified index to the end of the list.
 @discussion	The list returned by this method inherits the receiver's evaluator, but does not inherit it's quote/do construct status.
 */
- (STList *)sublistFromIndex:(NSUInteger)index;

#pragma mark -
#pragma mark Modification

/*!
 @abstract	Add an object to the end of the receiver.
 */
- (void)addObject:(id)object;

/*!
 @abstract	Insert an object into the receiver at a specified index.
 */
- (void)insertObject:(id)object atIndex:(NSUInteger)index;

#pragma mark -

/*!
 @abstract	Remove a specified object from the receiver.
 */
- (void)removeObject:(id)object;

/*!
 @abstract	Remove the object at a specified index from the receiver.
 */
- (void)removeObjectAtIndex:(NSUInteger)index;

#pragma mark -

- (void)replaceValuesByPerformingSelectorOnEachObject:(SEL)selector;

#pragma mark -
#pragma mark Finding Objects

/*!
 @abstract	Find the location of a specified object.
 */
- (NSUInteger)indexOfObject:(id)object;

/*!
 @abstract	Find the location of a specified object using a pointer comparison.
 */
- (NSUInteger)indexOfObjectIdenticalTo:(id)object;

#pragma mark -
#pragma mark Properties

/*!
 @abstract	Any flags specifying the structure of an STList object.
 */
@property STListFlags flags;

/*!
 @abstract	The location at which the list was created.
 */
@property STCreationLocation creationLocation;

#pragma mark -

/*!
 @abstract	The number of objects in the list.
 */
@property (readonly) NSUInteger count;

/*!
 @abstract	All of the objects in the list in the form of an array.
 */
@property (readonly) NSArray *allObjects;

@end
