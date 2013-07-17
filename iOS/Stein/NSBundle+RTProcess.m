//
//  NSBundle+RTProcess.m
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "NSBundle+RTProcess.h"
#import <objc/message.h>

@implementation NSBundle (RTProcess)

+ (void)load
{
    method_exchangeImplementations(class_getClassMethod(self, @selector(mainBundle)),
                                   class_getClassMethod(self, @selector(rt_mainBundle)));
}

#pragma mark -

static NSBundle *substituteMainBundle = nil;
+ (void)rt_setMainBundle:(NSBundle *)mainBundle
{
    substituteMainBundle = mainBundle;
}

+ (NSBundle *)rt_mainBundle
{
    if(substituteMainBundle)
        return substituteMainBundle;
    
    return [self rt_mainBundle];
}

+ (void)rt_resetMainBundle
{
    substituteMainBundle = nil;
}

@end
