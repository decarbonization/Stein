//
//  MethodsViewController.h
//  stein
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UIViewController.h"

@interface MethodsViewController : UIViewController <NSTableViewDataSource, NSTableViewDelegate>

#pragma mark - Outlets

@property (nonatomic, assign) IBOutlet NSTableView *tableView;

#pragma mark - Properties

@property (nonatomic, assign) Class introspectedClass;

@end
