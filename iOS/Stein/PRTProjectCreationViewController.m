//
//  PRTProjectCreationViewController.m
//  Stein
//
//  Created by Kevin MacWhinnie on 5/3/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "PRTProjectCreationViewController.h"

#import "PRTProjectManager.h"

@interface PRTProjectCreationViewController () <UITextFieldDelegate>

@end

@implementation PRTProjectCreationViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentSizeForViewInPopover = self.view.bounds.size;
    
    for (UITextField *observedTextField in self.observedTextFields) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldTextDidChange:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:observedTextField];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.nameTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)create:(id)sender
{
    [self.observedTextFields.lastObject resignFirstResponder];
    
    NSString *name = self.nameTextField.text;
    NSString *version = self.versionTextField.text;
    NSString *sanitizedName = [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *identifier = [self.identifierTextField.text stringByAppendingFormat:@".%@", sanitizedName];
    
    NSDictionary *infoDictionary = @{
        @"CFBundleName": name,
        @"CFBundleDisplayName": name,
        @"CFBundleIdentifier": identifier,
        @"CFBundleShortVersionString": version,
        @"CFBundleVersion": version,
        @"STRuntimeRequired": @YES,
        @"STMinimumVersion": @"*",
        @"LSRequiresIPhoneOS": @YES,
    };
    
    NSError *error = nil;
    if([[PRTProjectManager sharedProjectManager] createProjectWithInfoDictionary:infoDictionary error:&error]) {
        [self.delegate projectCreationViewControllerDidFinish:self];
    } else {
        [self.delegate projectCreationViewController:self didFailWithError:error];
    }
}

#pragma mark - Validation

- (BOOL)isNameValid
{
    return (self.nameTextField.text.length > 0);
}

- (BOOL)isIdentifierValid
{
    return (self.identifierTextField.text.length > 0);
}

- (BOOL)isVersionValid
{
    return (self.versionTextField.text.length > 0);
}

#pragma mark -

- (BOOL)areAllFieldsValid
{
    return (self.isNameValid &&
            self.isIdentifierValid &&
            self.isVersionValid);
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSUInteger indexOfTextField = [self.observedTextFields indexOfObject:textField];
    NSAssert((indexOfTextField != NSNotFound), @"Could not find text field.");
    
    if(indexOfTextField == self.observedTextFields.count - 1)
        textField.returnKeyType = UIReturnKeyDone;
    else
        textField.returnKeyType = UIReturnKeyNext;
    
    return YES;
}

- (void)textFieldTextDidChange:(NSNotification *)notification
{
    self.navigationBar.topItem.rightBarButtonItem.enabled = self.areAllFieldsValid;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSUInteger indexOfTextField = [self.observedTextFields indexOfObject:textField];
    NSAssert((indexOfTextField != NSNotFound), @"Could not find text field.");
    
    if(indexOfTextField == self.observedTextFields.count - 1) {
        [self create:nil];
    } else {
        [self.observedTextFields[indexOfTextField + 1] becomeFirstResponder];
    }
    
    return YES;
}

@end
