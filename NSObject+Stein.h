//
//  NSObject+Stein.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STList;
@interface NSObject (Stein)

#pragma mark Truthiness

+ (BOOL)isTrue;
- (BOOL)isTrue;

#pragma mark -
#pragma mark Control Flow

+ (id)if:(id)thenClause else:(id)elseClause;
- (id)if:(id)thenClause else:(id)elseClause;

#pragma mark -

+ (id)if:(id)thenClause;
- (id)if:(id)thenClause;

#pragma mark -

+ (id)ifNot:(id)thenClause else:(id)elseClause;
- (id)ifNot:(id)thenClause else:(id)elseClause;

#pragma mark -

+ (id)ifNot:(id)thenClause;
- (id)ifNot:(id)thenClause;

#pragma mark -

- (id)match:(STList *)matchers;

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
