//
//  RTProcess.h
//  Stein
//
//  Created by Kevin MacWhinnie on 1/13/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <Foundation/Foundation.h>

///The RTProcess class encapsulates the faux-process
///architecture used to run embedded Stein applications.
@interface RTProcess : NSObject

///Initialize the receiver with a given application bundle.
///
/// \param  bundle   The bundle to initialize the receiver with. Required.
///
/// \result A fully initialized faux-process object.
- (id)initWithBundle:(NSBundle *)bundle;

#pragma mark - Properties

///The bundle that the process belongs to.
@property (readonly) NSBundle *bundle;

///Whether or not the process is running.
@property (readonly) BOOL isRunning;

#pragma mark - Running Process

///Returns the currently running process.
+ (RTProcess *)runningProcess;

#pragma mark - Execution

///Runs the process.
///
///Upon invocation of this method, the Stein host application relinquishes most
///control of the user-facing interface and alters the return values of the
///following system-provided singletons:
///
/// * `+[UIApplication sharedApplication]`
/// * `+[NSBundle mainBundle]`
///
- (void)run;

///Moves the process's UI to the background.
///
///This method raises if the receiver is not running.
- (void)suspend;

///Moves the process's UI to the foreground.
///
///This method raises if the receiver is not running.
- (void)resume;

///Terminates the process.
///
/// \param  kill    Whether or not the process should be killed.
- (void)terminate:(BOOL)kill;

@end
