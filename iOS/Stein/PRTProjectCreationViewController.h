//
//  PRTProjectCreationViewController.h
//  Stein
//
//  Created by Kevin MacWhinnie on 5/3/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PRTProjectCreationViewControllerDelegate;

@interface PRTProjectCreationViewController : UIViewController

#pragma mark - Outlets

@property (nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (nonatomic) IBOutlet UITextField *nameTextField;

@property (nonatomic) IBOutlet UITextField *identifierTextField;

@property (nonatomic) IBOutlet UITextField *versionTextField;

@property (nonatomic) IBOutletCollection(UITextField) NSArray *observedTextFields;

#pragma mark - Properties

@property (nonatomic, weak) id <PRTProjectCreationViewControllerDelegate> delegate;

#pragma mark - Actions

- (IBAction)create:(id)sender;

@end

#pragma mark -

@protocol PRTProjectCreationViewControllerDelegate <NSObject>

- (void)projectCreationViewControllerDidFinish:(PRTProjectCreationViewController *)sender;

- (void)projectCreationViewController:(PRTProjectCreationViewController *)sender didFailWithError:(NSError *)error;

@end
