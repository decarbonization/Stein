//
//  RTProcess.m
//  Stein
//
//  Created by Kevin MacWhinnie on 1/13/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "RTProcess.h"
#import <libkern/OSAtomic.h>
#import "RTAppDelegate.h"
#import "NSBundle+RTProcess.h"

@interface RTProcess ()

@property (readwrite) NSBundle *bundle;

@property (readwrite) BOOL isRunning;

#pragma mark -

@property (nonatomic) NSURL *mainLocation;

@property (nonatomic) RTAppDelegate *appDelegate;

@end

@implementation RTProcess

- (void)dealloc
{
    
}

- (id)initWithBundle:(NSBundle *)bundle
{
    NSParameterAssert(bundle);
    
    if((self = [super init]))
    {
        self.bundle = bundle;
        
        self.mainLocation = [self.bundle URLForResource:@"Main" withExtension:@"st"];
        NSAssert(self.mainLocation, @"Malformed application, cannot find Main.st file.");
    }
    
    return self;
}

#pragma mark - Properties

- (UIApplication *)application
{
    return [UIApplication sharedApplication];
}

#pragma mark - Running Process

static RTProcess *_RunningProcess = nil;
+ (void)setRunningProcess:(RTProcess *)process
{
    _RunningProcess = process;
}

+ (RTProcess *)runningProcess
{
    return _RunningProcess;
}

#pragma mark - Execution

- (void)run
{
    if(self.isRunning)
        [NSException raise:NSInternalInconsistencyException format:@"Cannot run the same process twice."];
    
    [self.class.runningProcess terminate:NO];
    
    NSError *error = nil;
    NSString *main = [NSString stringWithContentsOfURL:self.mainLocation encoding:NSUTF8StringEncoding error:&error];
    NSAssert(main != nil, @"Could not load Main.st file. %@", error);
    
    [NSBundle rt_setMainBundle:self.bundle];
    
    Class AppDelegate = STEvaluate(STParseString(main, [self.mainLocation lastPathComponent]),
                                   STGetSharedRootScope());
    
    self.appDelegate = [AppDelegate new];
    [self.appDelegate application:self.application didFinishLaunchingWithOptions:@{}];
    
    UISwipeGestureRecognizer *suspendGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(suspend)];
    suspendGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    suspendGestureRecognizer.numberOfTouchesRequired = 2;
    [self.appDelegate.window addGestureRecognizer:suspendGestureRecognizer];
    
    self.class.runningProcess = self;
}

- (void)suspend
{
    if(!self.isRunning)
        [NSException raise:NSInternalInconsistencyException format:@"Cannot suspend a process that isn't running."];
    
    [self.appDelegate applicationWillResignActive:self.application];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.appDelegate.window.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.appDelegate applicationDidEnterBackground:self.application];
        
        self.appDelegate.window.hidden = YES;
        self.appDelegate.window.alpha = 1.0;
    }];
}

- (void)resume
{
    if(!self.isRunning)
        [NSException raise:NSInternalInconsistencyException format:@"Cannot resume a process that isn't running."];
    
    [self.appDelegate applicationWillEnterForeground:self.application];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.appDelegate.window.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self.appDelegate applicationDidBecomeActive:self.application];
    }];
}

- (void)terminate:(BOOL)kill
{
    if(kill) {
        [self terminate];
    } else {
        [self.appDelegate applicationWillTerminate:self.application];
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [self terminate];
        });
    }
}

- (void)terminate
{
    if(!self.isRunning)
        [NSException raise:NSInternalInconsistencyException format:@"Cannot terminate a non-running process."];
    
    [NSBundle rt_resetMainBundle];
    self.appDelegate = nil;
    self.class.runningProcess = nil;
}

@end
