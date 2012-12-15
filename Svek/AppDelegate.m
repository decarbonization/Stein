//
//  AppDelegate.m
//  Svek
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "AppDelegate.h"
#import "WorkspaceWindowController.h"

@implementation AppDelegate {
    WorkspaceWindowController *_workspaceWindowController;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.workspaceWindowController showWindow:nil];
}

- (WorkspaceWindowController *)workspaceWindowController
{
    if(!_workspaceWindowController)
    {
        _workspaceWindowController = [WorkspaceWindowController new];
    }
    
    return _workspaceWindowController;
}

@end
