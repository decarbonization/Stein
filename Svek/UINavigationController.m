//
//  NavigationController.m
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UINavigationController.h"
#import "UIViewController_Private.h"
#import "UIBarButton.h"

@interface UINavigationController ()

@end

@implementation UINavigationController

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithRootViewController:(UIViewController *)viewController
                        hostView:(NSView *)hostView
                   navigationBar:(UINavigationBar *)navigationBar
{
    NSParameterAssert(viewController);
    NSParameterAssert(hostView);
    
    if((self = [super init]))
    {
        self.view = hostView;
        
        _viewControllers = [NSMutableArray array];
        _navigationBar = navigationBar;
        
        [self pushViewController:viewController animated:NO];
    }
    
    return self;
}

#pragma mark - Properties

- (UIViewController *)topViewController
{
    return self.viewControllers[0];
}

- (UIViewController *)visibleViewController
{
    return [self.viewControllers lastObject];
}

@synthesize viewControllers = _viewControllers;
@synthesize navigationBar = _navigationBar;

#pragma mark - Pushing and Popping Stack Items

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSParameterAssert(viewController);
    
    NSAssert((viewController.navigationController == nil),
             @"Cannot push view controller %@ into multiple navigation controllers.", viewController);
    NSAssert((viewController.view.superview == nil),
              @"View controller %@ cannot be hosted in multiple places.", viewController);
    
    [_viewControllers addObject:viewController];
    viewController.navigationController = self;
    
    if(animated)
        [self replaceVisibleViewWithViewPushingFromRight:viewController.view];
    else
        [self replaceVisibleViewWithView:viewController.view];
    
    if([self.viewControllers count] > 1)
    {
        NSString *backButtonTitle = [self.viewControllers[self.viewControllers.count - 2] navigationItem].title;
        if([backButtonTitle length] > 15)
            backButtonTitle = @"Back";
        
        UIBarButton *backButton = [[UIBarButton alloc] initWithType:kUIBarButtonTypeBackButton
                                                              title:backButtonTitle
                                                             target:viewController
                                                             action:@selector(popFromNavigationController:)];
        viewController.navigationItem.leftView = backButton;
    }
    
    [_navigationBar pushNavigationItem:viewController.navigationItem animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    if([self.viewControllers count] == 1)
        return;
    
    UIViewController *visibleViewController = self.visibleViewController;
    [_viewControllers removeLastObject];
    visibleViewController.navigationController = nil;
    visibleViewController.navigationItem.leftView = nil;
    
    if(animated)
        [self replaceVisibleViewWithViewPushingFromLeft:self.visibleViewController.view];
    else
        [self replaceVisibleViewWithView:self.visibleViewController.view];
    
    [_navigationBar popNavigationItemAnimated:animated];
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSUInteger indexOfViewController = [self.viewControllers indexOfObject:viewController];
    NSAssert((indexOfViewController != NSNotFound),
             @"View controller %@ is not in navigation stack", viewController);
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexOfViewController + 1, _viewControllers.count - (indexOfViewController + 1))];
    [_viewControllers enumerateObjectsAtIndexes:indexesToRemove options:0 usingBlock:^(UIViewController *viewController, NSUInteger index, BOOL *stop) {
        viewController.navigationController = nil;
        viewController.navigationItem.leftView = nil;
    }];
    [_viewControllers removeObjectsAtIndexes:indexesToRemove];
    
    if(animated)
        [self replaceVisibleViewWithViewPushingFromLeft:viewController.view];
    else
        [self replaceVisibleViewWithView:viewController.view];
    
    [_navigationBar popToNavigationItem:viewController.navigationItem animated:animated];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    if([self.viewControllers count] == 1)
        return;
    
    UIViewController *topViewController = self.topViewController;
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _viewControllers.count - 1)];
    [_viewControllers enumerateObjectsAtIndexes:indexesToRemove options:0 usingBlock:^(UIViewController *viewController, NSUInteger index, BOOL *stop) {
        viewController.navigationController = nil;
        viewController.navigationItem.leftView = nil;
    }];
    [_viewControllers removeObjectsAtIndexes:indexesToRemove];
    
    if(animated)
        [self replaceVisibleViewWithViewPushingFromLeft:topViewController.view];
    else
        [self replaceVisibleViewWithView:topViewController.view];
    
    [_navigationBar popToRootNavigationItemAnimated:animated];
}

#pragma mark - Changing Views

- (void)replaceVisibleViewWithView:(NSView *)view
{
    if(_visibleView)
    {
        [_visibleView removeFromSuperviewWithoutNeedingDisplay];
        _visibleView = nil;
    }
    
    _visibleView = view;
    
    if(_visibleView)
    {
        [_visibleView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_visibleView setFrame:self.view.bounds];
        [self.view addSubview:_visibleView];
    }
}

- (void)replaceVisibleViewWithViewPushingFromLeft:(NSView *)newView
{
    if(!_visibleView)
    {
        [self replaceVisibleViewWithView:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.view.bounds;
    initialNewViewFrame.origin.x = -NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self.view addSubview:newView];
    
    NSView *oldView = _visibleView;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = NSMaxX(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleView = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
    }];
}

- (void)replaceVisibleViewWithViewPushingFromRight:(NSView *)newView
{
    if(!_visibleView)
    {
        [self replaceVisibleViewWithView:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.view.bounds;
    initialNewViewFrame.origin.x = NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self.view addSubview:newView];
    
    NSView *oldView = _visibleView;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = -NSWidth(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleView = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
    }];
}

@end
