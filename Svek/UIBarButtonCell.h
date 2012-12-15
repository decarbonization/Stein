//
//  UIBarButtonCell.h
//  Svek
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The different types of bar buttons.
typedef enum : NSUInteger {
    
    ///The default rounded type.
    kUIBarButtonTypeDefault = 0,
    
    ///The back button with an arrow on its left side.
    kUIBarButtonTypeBackButton = 1,
    
} UIBarButtonType;

///The UIBarButtonCell implements the display/sizing logic for the UIBarButton class.
@interface UIBarButtonCell : NSButtonCell

///Initialize the receiver with a given bar button type.
- (UIBarButtonCell *)initWithType:(UIBarButtonType)type title:(NSString *)title;

#pragma mark - Properties

///The type of the button.
@property (nonatomic) UIBarButtonType buttonType;

@end
