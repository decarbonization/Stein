//
//  STList.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STEvaluator;

/*!
 @class
 @abstract	The STList class is used to represent s-expressions in the Stein language.
 */
@interface STList : NSObject < NSFastEnumeration, NSCopying >
{
	/* owner */	NSMutableArray *mContents;
	/* n/a */	BOOL mIsQuoted;
	/* n/a */	BOOL mIsDoConstruct;
	/* weak */	STEvaluator *mEvaluator;
}
#pragma mark Creation

/*!
 @method
 @abstract	Initialize the receiver as an empty list.
 */
- (id)init;

/*!
 @method
 @abstract	Create a new autoreleased empty list.
 */
+ (STList *)list;

#pragma mark -

/*!
 @method
 @abstract	Initialize the receiver with a specified array.
 @param		array	The array to initialize the receiver's contents with. May not be nil.
 @result	A list with the contents of the specified array.
 */
- (id)initWithArray:(NSArray *)array;

/*!
 @method
 @abstract	Create a new autoreleased list with a specified array.
 @param		array	The array to use as list's contents. May not be nil.
 @result	A list with the contents of the specified array.
 */
+ (STList *)listWithArray:(NSArray *)array;

#pragma mark -

/*!
 @method
 @abstract		Initialize the receiver with the contents of a specified list.
 @param			list	The list to initialize the receiver's contents with. May not be nil.
 @result		A list with the contents of the specified list.
 @discussion	The receiver will also take the specified lists evaluator, and quote/do construct status.
 */
- (id)initWithList:(STList *)list;

/*!
 @method
 @abstract		Create a new autoreleased list with the contents of a specified list.
 @param			list	The list to use as the list's contents. May not be nil.
 @result		A list with the contents of the specified list.
 @discussion	The receiver will also take the specified lists evaluator, and quote/do construct status.
 */
+ (STList *)listWithList:(STList *)list;

#pragma mark -

- (id)initWithObject:(id)object;
+ (STList *)listWithObject:(id)object;

#pragma mark -
#pragma mark Accessing objects

/*!
 @method
 @abstract	Get the head of the list.
 @result	The head of the list; nil if the receiver is empty.
 */
- (id)head;

/*!
 @method
 @abstract	Get the tail (everything but the first object) of the list.
 @result	The tail of the list; an empty list of the receiver has less than two elements.
 */
- (STList *)tail;

#pragma mark -

/*!
 @method
 @abstract	Look up the object at a specified index in the receiver.
 */
- (id)objectAtIndex:(NSUInteger)index;

/*!
 @method
 @abstract		Create a new autoreleased sublist with the contents of the receiver in the specifeid range.
 @discussion	The list returned by this method inherits the receiver's evaluator, but does not inherit it's quote/do construct status.
 */
- (STList *)sublistWithRange:(NSRange)range;

#pragma mark -
#pragma mark Modification

/*!
 @method
 @abstract	Add an object to the end of the receiver.
 */
- (void)addObject:(id)object;

/*!
 @method
 @abstract	Insert an object into the receiver at a specified index.
 */
- (void)insertObject:(id)object atIndex:(NSUInteger)index;

#pragma mark -

/*!
 @method
 @abstract	Remove a specified object from the receiver.
 */
- (void)removeObject:(id)object;

/*!
 @method
 @abstract	Remove the object at a specified index from the receiver.
 */
- (void)removeObjectAtIndex:(NSUInteger)index;

#pragma mark -

- (void)replaceValuesByPerformingSelectorOnEachObject:(SEL)selector;

#pragma mark -
#pragma mark Finding Objects

/*!
 @method
 @abstract	Find the location of a specified object.
 */
- (NSUInteger)indexOfObject:(id)object;

/*!
 @method
 @abstract	Find the location of a specified object using a pointer comparison.
 */
- (NSUInteger)indexOfObjectIdenticalTo:(id)object;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	Whether or not the list is quoted.
 */
@property BOOL isQuoted;

/*!
 @property
 @abstract	Whether or not the list is a do construct (was created with square brackets).
 */
@property BOOL isDoConstruct;

#pragma mark -

/*!
 @property
 @abstract	The evaluator the list is bound to.
 */
@property (assign) STEvaluator *evaluator;

#pragma mark -

/*!
 @property
 @abstract	The number of objects in the list.
 */
@property (readonly) NSUInteger count;

/*!
 @property
 @abstract	All of the objects in the list in the form of an array.
 */
@property (readonly) NSArray *allObjects;

@end
