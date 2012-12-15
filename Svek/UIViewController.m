//
//  UIViewController.m
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UIViewController.h"
#import "UIViewController_Private.h"
#import "UINavigationController.h"
#import "UINavigationItem.h"

@implementation UIViewController

- (id)initWithView:(NSView *)view
{
    NSParameterAssert(view);
    
    if((self = [super init]))
    {
        [self viewWillLoad];
        
        self.view = view;
        self.isLoaded = YES;
        
        [self viewDidLoad];
    }
    
    return self;
}

- (id)init
{
    return [super initWithNibName:NSStringFromClass([self class])
                           bundle:[NSBundle bundleForClass:[self class]]];
}

#pragma mark - Loading

- (void)viewWillLoad
{
}

- (void)viewDidLoad
{
}

- (void)loadView
{
    if(!self.isLoaded)
    {
        [self viewWillLoad];
        
        [super loadView];
        self.isLoaded = YES;
        
        [self viewDidLoad];
    }
}

#pragma mark - Properties

- (UINavigationItem *)navigationItem
{
    if(!_navigationItem)
    {
        _navigationItem = [UINavigationItem new];
        _navigationItem.title = NSStringFromClass([self class]);
    }
    
    return _navigationItem;
}

#pragma mark - Actions

- (IBAction)popFromNavigationController:(id)sender
{
    if(self.navigationController.visibleViewController == self)
        [self.navigationController popViewControllerAnimated:YES];
}

@end
