//
//  RootViewController.m
//  Stein
//
//  Created by Kevin MacWhinnie on 1/12/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "PRTRootViewController.h"
#import "PRTProjectManagerViewController.h"
#import "RTHostViewController.h"

@interface PRTRootViewController () <UISplitViewControllerDelegate>

@end

@implementation PRTRootViewController

+ (PRTRootViewController *)sharedRootViewController
{
    static PRTRootViewController *sharedRootViewController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRootViewController = [PRTRootViewController new];
    });
    
    return sharedRootViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UISplitViewController *splitViewController = [UISplitViewController new];
    RTHostViewController *hostViewController = [RTHostViewController new];
    PRTProjectManagerViewController *projectManagerController = [[PRTProjectManagerViewController alloc] initWithHostViewController:hostViewController];
    UINavigationController *projectNavigationController = [[UINavigationController alloc] initWithRootViewController:projectManagerController];
    splitViewController.viewControllers = @[ projectNavigationController, hostViewController ];
    splitViewController.presentsWithGesture = NO;
    splitViewController.delegate = self;
    self.viewController = splitViewController;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Properties

- (void)setViewController:(UIViewController *)viewController
{
    if(!self.isViewLoaded)
        [self loadView];
    
    if(_viewController)
    {
        [_viewController removeFromParentViewController];
        [_viewController.view removeFromSuperview];
    }
    
    _viewController = viewController;
    
    if(viewController)
    {
        viewController.view.frame = self.view.bounds;
        viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:viewController.view];
        
        [self addChildViewController:viewController];
    }
}

#pragma mark - <UISplitViewDelegate>

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

@end
