//
//  WorkspaceWindowController.m
//  stein
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "WorkspaceWindowController.h"
#import "UINavigationController.h"

#import "ClassesViewController.h"

@implementation WorkspaceWindowController

- (id)init
{
    if((self = [super initWithWindowNibName:@"WorkspaceWindowController"]))
    {
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self window] center];
    
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:[ClassesViewController new]
                                                                                  hostView:self.contentView
                                                                             navigationBar:self.navigationBar];
}

@end
