//
//  NSObject+SteinClassAdditions.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STClosure;
@interface NSObject (SteinClassAdditions)

#pragma mark Extension

+ (Class)extend:(STClosure *)expressions;

#pragma mark -
#pragma mark Subclassing

+ (Class)subclass:(NSString *)subclassName;
+ (Class)subclass:(NSString *)subclassName where:(STClosure *)expressions;

#pragma mark -
#pragma mark Ivars

- (void)setValue:(id)value forIvarNamed:(NSString *)name;
- (id)valueForIvarNamed:(NSString *)name;

@end
