//
//  NSObject+Stein.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol STFunction;
@class STClosure;

@interface NSObject (Stein)

#pragma mark Truthiness

+ (BOOL)isTrue;
- (BOOL)isTrue;

#pragma mark -
#pragma mark Control Flow

+ (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause;
- (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause;

#pragma mark -

+ (id)ifTrue:(id < STFunction >)thenClause;
- (id)ifTrue:(id < STFunction >)thenClause;

#pragma mark -

+ (id)ifFalse:(id < STFunction >)thenClause ifTrue:(id < STFunction >)elseClause;
- (id)ifFalse:(id < STFunction >)thenClause ifTrue:(id < STFunction >)elseClause;

#pragma mark -

+ (id)ifFalse:(id < STFunction >)thenClause;
- (id)ifFalse:(id < STFunction >)thenClause;

#pragma mark -

- (id)match:(STClosure *)matchers;

#pragma mark -
#pragma mark Printing

- (NSString *)print;

@end

#pragma mark -

@interface NSNumber (Stein)

- (BOOL)isTrue;

@end

#pragma mark -

@interface NSNull (Stein)

+ (BOOL)isTrue;
- (BOOL)isTrue;

@end

#pragma mark -

@interface NSArray (Stein)

- (void)foreach:(STClosure *)closure;
- (NSArray *)map:(STClosure *)closure;
- (NSArray *)filter:(STClosure *)closure;

@end

@interface NSSet (Stein)

- (void)foreach:(STClosure *)closure;
- (NSSet *)map:(STClosure *)closure;
- (NSSet *)filter:(STClosure *)closure;

@end
