//
//  PRTProjectDetailViewController.m
//  Stein
//
//  Created by Kevin MacWhinnie on 5/3/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "PRTProjectDetailViewController.h"

#import "RTProcess.h"

@interface PRTProjectDetailViewController ()

@property (nonatomic) NSArray *projectFileURLs;

@end

@implementation PRTProjectDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSError *error = nil;
    self.projectFileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.projectURL includingPropertiesForKeys:@[] options:0 error:&error];
    if(!self.projectFileURLs) {
        NSLog(@"Could not get project URLs. Error %@", error);
    }
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projectFileURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Project Cell Identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *fileURL = self.projectFileURLs[indexPath.row];
    cell.textLabel.text = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    cell.detailTextLabel.text = [fileURL pathExtension];
}

#pragma mark -

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSBundle *bundle = [NSBundle bundleWithURL:self.projectURL];
    [[[RTProcess alloc] initWithBundle:bundle] run];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
