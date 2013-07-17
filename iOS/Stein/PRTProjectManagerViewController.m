//
//  PRTProjectManagerViewController.m
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "PRTProjectManagerViewController.h"
#import "PRTProjectManager.h"

#import "RTHostViewController.h"
#import "PRTConsoleViewController.h"
#import "PRTProjectCreationViewController.h"
#import "PRTProjectDetailViewController.h"

enum {
    kConsoleSection,
    kProjectsSection,
    
    kNumberSections
};

@interface PRTProjectManagerViewController () <UIPopoverControllerDelegate, PRTProjectCreationViewControllerDelegate>

@property (nonatomic) UIPopoverController *createProjectPopover;

@property (nonatomic) PRTProjectManager *projectManager;

@property (nonatomic, readwrite) RTHostViewController *hostViewController;

@end

@implementation PRTProjectManagerViewController

- (id)initWithHostViewController:(RTHostViewController *)hostViewController
{
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.projectManager = [PRTProjectManager sharedProjectManager];
        self.hostViewController = hostViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                          target:self
                                                                                          action:@selector(addProject:)];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = @"Projects";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.projectManager addObserver:self forKeyPath:@"projectURLs" options:0 context:NULL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(![self.tableView indexPathForSelectedRow]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:kConsoleSection];
        [self.tableView selectRowAtIndexPath:indexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionTop];
        
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.projectManager removeObserver:self forKeyPath:@"projectURLs"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Observations

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == _projectManager && [keyPath isEqualToString:@"projectURLs"]) {
        [self.tableView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Actions

- (IBAction)addProject:(UIBarButtonItem *)sender
{
    if(self.createProjectPopover)
        return;
    
    PRTProjectCreationViewController *projectCreationController = [PRTProjectCreationViewController new];
    projectCreationController.delegate = self;
    
    self.createProjectPopover = [[UIPopoverController alloc] initWithContentViewController:projectCreationController];
    self.createProjectPopover.delegate = self;
    [self.createProjectPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.createProjectPopover = nil;
}

#pragma mark - <PRTProjectCreationViewControllerDelegate>

- (void)projectCreationViewControllerDidFinish:(PRTProjectCreationViewController *)sender
{
    [self.createProjectPopover dismissPopoverAnimated:YES];
}

- (void)projectCreationViewController:(PRTProjectCreationViewController *)sender didFailWithError:(NSError *)error
{
    [self.createProjectPopover dismissPopoverAnimated:YES];
    
    [[NSString stringWithFormat:@"Could not create project. Error: %@", [error localizedDescription]] print];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == kConsoleSection)
        return 1;
    else if(section == kProjectsSection)
        return _projectManager.projectURLs.count;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Project Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == kProjectsSection);
}
 
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSURL *projectURL = _projectManager.projectURLs[indexPath.row];
        
        NSError *error = nil;
        if([[PRTProjectManager sharedProjectManager] deleteProjectAtURL:projectURL error:&error]) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [[NSString stringWithFormat:@"Could not delete project. Error: %@", [error localizedDescription]] print];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == kConsoleSection) {
        cell.textLabel.text = @"Console";
    } else if(indexPath.section == kProjectsSection) {
        NSURL *projectURL = _projectManager.projectURLs[indexPath.row];
        cell.textLabel.text = [[projectURL lastPathComponent] stringByDeletingPathExtension];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == kConsoleSection) {
        self.hostViewController.viewController = [PRTConsoleViewController new];
    } else if(indexPath.section == kProjectsSection) {
        self.hostViewController.viewController = nil;
        
        PRTProjectDetailViewController *detailViewController = [PRTProjectDetailViewController new];
        detailViewController.hostViewController = self.hostViewController;
        detailViewController.projectURL = _projectManager.projectURLs[indexPath.row];
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}

@end
