//
//  UINavigationItem.h
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UIBarButton.h"

///The UINavigationItem encapsulates information about a navigation item pushed onto an UINavigationBar's stack.
///
///By default a navigation item has no left or right button and has a borderless NSTextField as its title view.
@interface UINavigationItem : NSView

#pragma mark - Properties

///The title of the navigation item.
///
///This property does nothing if the title view is not an NSTextField instance (default).
@property (nonatomic, copy) NSString *title;

#pragma mark - Views

///The left button of the navigation item.
@property (nonatomic) NSView *leftView;

///The title view of the navigation item.
@property (nonatomic) NSView *titleView;

///The right button of the navigation item.
@property (nonatomic) NSView *rightView;

@end
