//
//  UIViewController_Private.h
//  Convert Finder
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "UIViewController.h"

@interface UIViewController ()

///Readwrite
@property (nonatomic, readwrite) BOOL isLoaded;

///Readwrite
@property (nonatomic, readwrite, weak) UINavigationController *navigationController;

@end
