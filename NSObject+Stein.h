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

+ (id)if:(id < STFunction >)thenClause else:(id < STFunction >)elseClause;
- (id)if:(id < STFunction >)thenClause else:(id < STFunction >)elseClause;

#pragma mark -

+ (id)if:(id < STFunction >)thenClause;
- (id)if:(id < STFunction >)thenClause;

#pragma mark -

+ (id)ifNot:(id < STFunction >)thenClause else:(id < STFunction >)elseClause;
- (id)ifNot:(id < STFunction >)thenClause else:(id < STFunction >)elseClause;

#pragma mark -

+ (id)ifNot:(id < STFunction >)thenClause;
- (id)ifNot:(id < STFunction >)thenClause;

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
