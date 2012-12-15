//
//  UINavigationBar.m
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UINavigationBar.h"

@implementation UINavigationBar

- (id)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect]))
    {
        _navigationItems = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect drawingRect = [self bounds];
    
    NSRect bottomLineRect = NSMakeRect(NSMinX(drawingRect), NSMinY(drawingRect), NSWidth(drawingRect), 1.0);
    [[NSColor darkGrayColor] set];
    [NSBezierPath fillRect:bottomLineRect];
}

#pragma mark - Properties

- (NSArray *)navigationItems
{
    return [_navigationItems copy];
}

- (UINavigationItem *)topNavigationItem
{
    return _navigationItems[0];
}

- (UINavigationItem *)visibleNavigationItem
{
    return [_navigationItems lastObject];
}

#pragma mark - Pushing and Popping Items

- (void)pushNavigationItem:(UINavigationItem *)navigationItem animated:(BOOL)animated
{
    NSParameterAssert(navigationItem);
    
    NSAssert(![_navigationItems containsObject:navigationItem],
             @"Cannot push navigation item %@ more than once", navigationItem);
    
    [_navigationItems addObject:navigationItem];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromRight:navigationItem];
    else
        [self replaceVisibleNavigationItemWith:navigationItem];
}

- (void)popNavigationItemAnimated:(BOOL)animated
{
    if([_navigationItems count] == 1)
        return;
    
    [_navigationItems removeLastObject];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromLeft:self.visibleNavigationItem];
    else
        [self replaceVisibleNavigationItemWith:self.visibleNavigationItem];
}

- (void)popToNavigationItem:(UINavigationItem *)navigationItem animated:(BOOL)animated
{
    NSParameterAssert(navigationItem);
    
    NSInteger indexOfNavigationItem = [_navigationItems indexOfObject:navigationItem];
    NSAssert(indexOfNavigationItem != NSNotFound,
             @"Cannot pop from navigation item %@ that isn't in stack", navigationItem);
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexOfNavigationItem + 1, _navigationItems.count - (indexOfNavigationItem + 1))];
    [_navigationItems removeObjectsAtIndexes:indexesToRemove];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromLeft:navigationItem];
    else
        [self replaceVisibleNavigationItemWith:navigationItem];
}

- (void)popToRootNavigationItemAnimated:(BOOL)animated
{
    if([self.navigationItems count] == 1)
        return;
    
    UINavigationItem *topNavigationItem = self.topNavigationItem;
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _navigationItems.count - 1)];
    [_navigationItems removeObjectsAtIndexes:indexesToRemove];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromLeft:topNavigationItem];
    else
        [self replaceVisibleNavigationItemWith:topNavigationItem];
}

#pragma mark - Changing Frame Views

- (void)replaceVisibleNavigationItemWith:(UINavigationItem *)view
{
    if(_visibleNavigationItem)
    {
        [_visibleNavigationItem removeFromSuperviewWithoutNeedingDisplay];
        _visibleNavigationItem = nil;
    }
    
    _visibleNavigationItem = view;
    
    if(_visibleNavigationItem)
    {
        [_visibleNavigationItem setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_visibleNavigationItem setFrame:self.bounds];
        [self addSubview:_visibleNavigationItem];
    }
}

- (void)replaceVisibleNavigationItemPushingFromLeft:(UINavigationItem *)newView
{
    if(!_visibleNavigationItem)
    {
        [self replaceVisibleNavigationItemWith:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.bounds;
    initialNewViewFrame.origin.x = -NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self addSubview:newView];
    
    NSView *oldView = _visibleNavigationItem;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = NSMaxX(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleNavigationItem = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setAlphaValue:0.0];
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
        [oldView setAlphaValue:1.0];
    }];
}

- (void)replaceVisibleNavigationItemPushingFromRight:(UINavigationItem *)newView
{
    if(!_visibleNavigationItem)
    {
        [self replaceVisibleNavigationItemWith:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.bounds;
    initialNewViewFrame.origin.x = NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self addSubview:newView];
    
    NSView *oldView = _visibleNavigationItem;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = -NSWidth(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleNavigationItem = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setAlphaValue:0.0];
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
        [oldView setAlphaValue:1.0];
    }];
}

@end
