//
//  REPLViewController.h
//  Stein
//
//  Created by Kevin MacWhinnie on 1/12/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRTConsoleViewController : UIViewController <UITextViewDelegate>

///Returns the shared console view controller object, creating it if it does not exist.
+ (instancetype)sharedConsoleViewController;

#pragma mark - Outlets

@property (nonatomic) IBOutlet UITextView *textView;

@property (nonatomic) IBOutlet UIView *inputAccessoryView;

#pragma mark - Actions

- (IBAction)clear:(id)sender;

- (IBAction)reset:(id)sender;

#pragma mark -

- (IBAction)insertTab:(id)sender;

- (IBAction)insertSpecialCharacterFrom:(UIButton *)sender;

#pragma mark -

- (IBAction)moveUpThroughHistory:(id)sender;

- (IBAction)moveDownThroughHistory:(id)sender;

#pragma mark - Interactivity

- (void)write:(NSString *)text;

- (void)writeLine:(NSString *)text;

@end
