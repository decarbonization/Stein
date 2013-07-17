//
//  RTAppDelegate.h
//  Stein
//
//  Created by Kevin MacWhinnie on 1/13/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTAppDelegate : NSObject <UIApplicationDelegate>

#pragma mark - Properties

///The window that belongs to the app delegate.
@property (nonatomic) UIWindow *window;

@end

/*
 Default implementations are provided for:
 
 - (void)applicationDidFinishLaunching:(UIApplication *)application
 - (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 - (void)applicationDidBecomeActive:(UIApplication *)application
 - (void)applicationWillResignActive:(UIApplication *)application
 - (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
 - (void)applicationWillTerminate:(UIApplication *)application
 - (void)applicationDidEnterBackground:(UIApplication *)application
 - (void)applicationWillEnterForeground:(UIApplication *)application
 */
