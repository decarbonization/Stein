//
//  RootViewController.h
//  Stein
//
//  Created by Kevin MacWhinnie on 1/12/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRTRootViewController : UIViewController

///Returns the shared instance, creating it if it does not already exist.
+ (PRTRootViewController *)sharedRootViewController;

#pragma mark - Properties

///The view controller currently being displayed.
@property (nonatomic) UIViewController *viewController;

@end
