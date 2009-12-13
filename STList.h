//
//  STList.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STEvaluator;
@interface STList : NSObject < NSFastEnumeration, NSCopying >
{
	NSMutableArray *mContents;
	BOOL mIsQuoted;
	STEvaluator *mEvaluator;
}
#pragma mark Creation

- (id)init;
+ (STList *)list;

- (id)initWithArray:(NSArray *)array;
+ (STList *)listWithArray:(NSArray *)array;

- (id)initWithList:(STList *)list;
+ (STList *)listWithList:(STList *)list;

#pragma mark -
#pragma mark Accessing objects

- (id)head;
- (STList *)tail;

#pragma mark -

- (id)objectAtIndex:(NSUInteger)index;
- (STList *)sublistWithRange:(NSRange)range;

#pragma mark -
#pragma mark Modification

- (void)addObject:(id)object;
- (void)insertObject:(id)object atIndex:(NSUInteger)index;
- (void)removeObject:(id)object;
- (void)removeObjectAtIndex:(NSUInteger)index;

#pragma mark -
#pragma mark Finding Objects

- (NSUInteger)indexOfObject:(id)object;
- (NSUInteger)indexOfObjectIdenticalTo:(id)object;

#pragma mark -
#pragma mark Properties

@property BOOL isQuoted;
@property (assign) STEvaluator *evaluator;
@property (readonly) NSUInteger count;

@end
