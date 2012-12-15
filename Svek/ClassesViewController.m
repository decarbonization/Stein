//
//  ClassesViewController.m
//  stein
//
//  Created by Kevin MacWhinnie on 12/14/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "ClassesViewController.h"
#import "RKPrelude.h"
#import "UINavigationController.h"
#import <Stein/STIntrospection.h>

#import "MethodsViewController.h"

@interface ClassesViewController ()

@property (nonatomic) NSArray *classes;

@end

@implementation ClassesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Classes";
    
    [self reloadClasses];
}

- (void)reloadClasses
{
    self.classes = [RKCollectionFilterToArray([NSObject subclasses], ^BOOL(Class class) {
        NSString *className = NSStringFromClass(class);
        return ![className hasPrefix:@"_"];
    }) sortedArrayUsingComparator:^NSComparisonResult(Class left, Class right) {
        NSString *leftClassName = NSStringFromClass(left);
        NSString *rightClassName = NSStringFromClass(right);
        
        return [leftClassName compare:rightClassName];
    }];
    
    [self.tableView reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.classes.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cell = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    
    Class subclass = self.classes[row];
    cell.textField.stringValue = NSStringFromClass(subclass);
    
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = [notification object];
    NSIndexSet *selectedRows = [tableView selectedRowIndexes];
    if([selectedRows count] == 1)
    {
        MethodsViewController *methodsViewController = [MethodsViewController new];
        methodsViewController.introspectedClass = self.classes[selectedRows.lastIndex];
        [self.navigationController pushViewController:methodsViewController animated:YES];
    }
    
    [tableView deselectAll:nil];
}

@end
