//
//  UINavigationBar.h
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UINavigationItem.h"

///The UINavigationBar class implements a control for navigating hierarchical content.
@interface UINavigationBar : NSView
{
    UINavigationItem *_visibleNavigationItem;
    NSMutableArray *_navigationItems;
}

#pragma mark - Properties

///The navigation items of the bar.
@property (nonatomic, copy, readonly) NSArray *navigationItems;

///The item at the top of the navigation bar's stack.
@property (nonatomic, readonly) UINavigationItem *topNavigationItem;

///The item currently visible to the user.
@property (nonatomic, readonly) UINavigationItem *visibleNavigationItem;

#pragma mark - Pushing and Popping Items

///Pushes the given navigation item onto the receiver’s stack and updates the navigation bar.
- (void)pushNavigationItem:(UINavigationItem *)navigationItem animated:(BOOL)animated;

///Pops the top item from the receiver’s stack and updates the navigation bar.
- (void)popNavigationItemAnimated:(BOOL)animated;

///Pops navigation items until the specified navigation item is at the top of the navigation stack.
- (void)popToNavigationItem:(UINavigationItem *)navigationItem animated:(BOOL)animated;

///Pops all the navigation on the stack except the top most.
- (void)popToRootNavigationItemAnimated:(BOOL)animated;

@end
