//
//  RTHostViewController.m
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "RTHostViewController.h"

@interface RTHostViewController ()

@end

@implementation RTHostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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

@end
