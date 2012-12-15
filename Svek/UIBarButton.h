//
//  UIBarButton.h
//  Svek
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UIBarButtonCell.h"

///The UIBarButton class is a subclass of NSButton used by UINavigationItem
///instances to present navigation options to the user.
///
///Changing the title of image of a bar button will cause it to update its metrics.
@interface UIBarButton : NSButton

///Initialize the receiver with a given button type and basic parameters.
- (id)initWithType:(UIBarButtonType)type
             title:(NSString *)title
            target:(id)target
            action:(SEL)action;

#pragma mark - Properties

///The type of the button.
@property (nonatomic) UIBarButtonType buttonType;

@end
