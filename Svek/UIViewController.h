//
//  UIViewController.h
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UINavigationController, UINavigationItem;

///The subclass of NSViewController used by live nation apps.
@interface UIViewController : NSViewController
{
    UINavigationItem *_navigationItem;
}

///Initialize the receiver to represent a given view.
- (id)initWithView:(NSView *)view;

#pragma mark - Loading

///Invoked when the view is about to load.
///
///Subclasses do not need to invoke super.
- (void)viewWillLoad;

///Invoked when the view has loaded.
///
///Subclasses do not need to invoke super.
- (void)viewDidLoad;

#pragma mark - Properties

///Whether or not the view controller is loaded.
@property (nonatomic, readonly) BOOL isLoaded;

///The navigation controller that contains this view controller.
///
///This property will automatically be set when the view controller
///is placed within a navigation controller.
@property (nonatomic, readonly, weak) UINavigationController *navigationController;

///The navigation item of the view controller.
///
///The default implementation of this property provides a factory navigation item.
@property (nonatomic, readonly) UINavigationItem *navigationItem;

#pragma mark - Actions

///Causes the receiver to pop itself from its containing navigation controller.
///
///This method does nothing if the receiver's `.navigationController` is not set.
- (IBAction)popFromNavigationController:(id)sender;

@end
