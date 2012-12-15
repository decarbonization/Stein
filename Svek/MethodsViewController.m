//
//  MethodsViewController.m
//  stein
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "MethodsViewController.h"

#import "UINavigationController.h"

#import "STIntrospection.h"

@interface MethodsViewController ()

@property (nonatomic) NSArray *methods;

@end

@implementation MethodsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Properties

- (void)setIntrospectedClass:(Class)introspectedClass
{
    _introspectedClass = introspectedClass;
    
    self.methods = [introspectedClass methods];
    [self.tableView reloadData];
    
    self.navigationItem.title = NSStringFromClass(introspectedClass);
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.methods.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cell = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    
    STMethod *method = self.methods[row];
    cell.textField.stringValue = [NSString stringWithFormat:@"%@[%@ %@]", method.isInstanceMethod? @"-" : @"+", self.introspectedClass, method.name];
    
    return cell;
}

@end
