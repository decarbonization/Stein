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
#import "PromptViewController.h"

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
    
    self.classNavigationController = [[UINavigationController alloc] initWithRootViewController:[ClassesViewController new]
                                                                                  hostView:self.classHostView
                                                                             navigationBar:self.classNavigationBar];
    
    self.promptNavigationController = [[UINavigationController alloc] initWithRootViewController:[PromptViewController new]
                                                                                        hostView:self.promptHostView
                                                                                   navigationBar:self.promptNavigationBar];
}

@end
