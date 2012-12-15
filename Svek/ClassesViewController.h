//
//  ClassesViewController.h
//  stein
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UIViewController.h"

@interface ClassesViewController : UIViewController <NSTableViewDataSource, NSTableViewDelegate>

#pragma mark - Outlets

@property (nonatomic, assign) IBOutlet NSTableView *tableView;

@end
