//
//  UIBarButton.m
//  Svek
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UIBarButton.h"

@implementation UIBarButton

- (id)initWithType:(UIBarButtonType)type title:(NSString *)title target:(id)target action:(SEL)action
{
    if((self = [super initWithFrame:NSZeroRect]))
    {
        UIBarButtonCell *cell = [[UIBarButtonCell alloc] initWithType:type title:title];
        [self setCell:cell];
        [self setTarget:target];
        [self setAction:action];
        
        [self sizeToFit];
    }
    
    return self;
}

#pragma mark - Properties

- (void)setButtonType:(UIBarButtonType)buttonType
{
    [(UIBarButtonCell *)[self cell] setButtonType:buttonType];
    
    [self sizeToFit];
}

- (UIBarButtonType)buttonType
{
    return [(UIBarButtonCell *)[self cell] buttonType];
}

- (void)setTitle:(NSString *)aString
{
    [super setTitle:aString];
    
    [self sizeToFit];
}

- (void)setImage:(NSImage *)image
{
    [super setImage:image];
    
    [self sizeToFit];
}

@end
