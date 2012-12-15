//
//  WorkspaceWindowController.h
//  stein
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UINavigationBar, UINavigationController;

@interface WorkspaceWindowController : NSWindowController

#pragma mark - Outlets

@property (nonatomic, assign) IBOutlet UINavigationBar *navigationBar;

@property (nonatomic, assign) IBOutlet NSView *contentView;

#pragma mark - Properties

@property (nonatomic) UINavigationController *navigationController;

@end
