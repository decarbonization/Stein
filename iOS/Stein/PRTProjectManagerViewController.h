//
//  PRTProjectManagerViewController.h
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTHostViewController;

@interface PRTProjectManagerViewController : UITableViewController

- (id)initWithHostViewController:(RTHostViewController *)hostViewController;

#pragma mark - Properties

@property (nonatomic, readonly) RTHostViewController *hostViewController;

@end
