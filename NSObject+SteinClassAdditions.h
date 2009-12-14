//
//  NSObject+SteinClassAdditions.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STList;
@interface NSObject (SteinClassAdditions)

#pragma mark -
#pragma mark Extension

+ (Class)extend:(STList *)expressions;

#pragma mark Subclassing

+ (Class)subclass:(NSString *)subclassName;
+ (Class)subclass:(NSString *)subclassName where:(STList *)expressions;

@end
