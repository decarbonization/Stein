//
//  NavigationController.h
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UIViewController.h"
#import "UINavigationBar.h"

///The UINavigationController class implements a specialized view controller that manages the navigation of hierarchical content.
@interface UINavigationController : UIViewController
{
    NSMutableArray *_viewControllers;
    NSView *_visibleView;
    UINavigationBar *_navigationBar;
}

///Initialize the receier with a given root view controller.
///
/// \param  viewController  The view controller that resides at the bottom of the navigation stack. Required.
/// \param  hostView        The view that displays the contents of this controller. Required.
/// \param  navigationBar   The navigation bar associated with this navigation controller. Optional.
///
///This is the designated initializer.
- (id)initWithRootViewController:(UIViewController *)viewController
                        hostView:(NSView *)hostView
                   navigationBar:(UINavigationBar *)navigationBar;

#pragma mark - Properties

///The view controller at the root of the navigation stack.
@property (nonatomic, readonly) UIViewController *topViewController;

///The view controller that is currently visible to the user.
@property (nonatomic, readonly) UIViewController *visibleViewController;

///The view controllers on the stack.
@property (nonatomic, readonly, copy) NSArray *viewControllers;

///The navigation bar associated with this navigation controller.
@property (nonatomic, readonly) UINavigationBar *navigationBar;

#pragma mark - Pushing and Popping Stack Items

///Pushes a view controller onto the receiver’s stack and updates the display.
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

///Pops the top view controller from the navigation stack and updates the display.
- (void)popViewControllerAnimated:(BOOL)animated;

///Pops view controllers until the specified view controller is at the top of the navigation stack.
- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

///Pops all the view controllers on the stack except the root view controller and updates the display.
- (void)popToRootViewControllerAnimated:(BOOL)animated;

@end
