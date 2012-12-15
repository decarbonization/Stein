//
//  AppDelegate.h
//  Svek
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WorkspaceWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly) WorkspaceWindowController *workspaceWindowController;

@end
