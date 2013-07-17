//
//  PRTProjectDetailViewController.h
//  Stein
//
//  Created by Kevin MacWhinnie on 5/3/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTHostViewController;

@interface PRTProjectDetailViewController : UITableViewController

#pragma mark - Properties

@property (nonatomic) RTHostViewController *hostViewController;

@property (nonatomic) NSURL *projectURL;

@end
