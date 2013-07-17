//
//  NSBundle+RTProcess.h
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <Foundation/Foundation.h>

///The NSBundle+RTProcess category adds the methods necessary to change `+[NSBundle mainBundle]`.
@interface NSBundle (RTProcess)

///Sets the value returned by `+[NSBundle mainBundle]`.
///
///This method is used by RTProcess to relinquish control of the host application.
+ (void)rt_setMainBundle:(NSBundle *)mainBundle;

///Resets the value of `+[NSBundle mainBundle]` to its default value.
+ (void)rt_resetMainBundle;

@end
