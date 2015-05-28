//
//  Copyright (C) 2015 Warm Showers Foundation
//  http://warmshowers.org/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "LeftMenuViewController.h"
#import "UIViewController+ECSlidingViewController.h"
#import "SearchHostsTableViewController.h"
#import "FavouriteHostTableViewController.h"
#import "AllThreadsTableViewController.h"
#import "WSAppDelegate.h"
#import "RHAboutViewController.h"

@interface LeftMenuViewController ()
@property (nonatomic, strong) RHTableView *tableView;
-(RHBarButtonItem *)leftMenuButton;
@end

@implementation LeftMenuViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"Warm Showers", nil)];
    
    [self.tableView addSectionWithSectionHeaderText:NSLocalizedString(@"Find a Host", nil)];
    
    __weak LeftMenuViewController *bself = self;
    
    RHTableViewCell *cell = [RHTableViewCell cellWithLabelText:NSLocalizedString(@"Map", nil)
                                               detailLabelText:nil
                                                didSelectBlock:^{
                                                    UIViewController *controller = self.hostMapViewController;
                                                    [bself.slidingViewController setTopViewController:[controller wrapInNavigationController]];
                                                    [bself.slidingViewController resetTopViewAnimated:YES];
                                                }
                                                         style:UITableViewCellStyleDefault
                                                         image:[[UIImage imageNamed:@"193-location-arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                 accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [self.tableView addCell:cell];
    
    cell = [RHTableViewCell cellWithLabelText:NSLocalizedString(@"Search", nil)
                              detailLabelText:nil
                               didSelectBlock:^{
                                   UIViewController *controller = [[SearchHostsTableViewController alloc] initWithStyle:UITableViewStylePlain];
                                   [controller.navigationItem setLeftBarButtonItem:[self leftMenuButton]];
                                   [bself.slidingViewController setTopViewController:[controller wrapInNavigationController]];
                                   [bself.slidingViewController resetTopViewAnimated:YES];
                               }
                                        style:UITableViewCellStyleDefault
                                        image:[[UIImage imageNamed:@"06-magnify"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [self.tableView addCell:cell];
    
    cell = [RHTableViewCell cellWithLabelText:NSLocalizedString(@"Favourites", nil)
                              detailLabelText:nil
                               didSelectBlock:^{
                                   
                                   UIViewController *controller = [[FavouriteHostTableViewController alloc] initWithStyle:UITableViewStylePlain];
                                   
                                   [controller.navigationItem setLeftBarButtonItem:[self leftMenuButton]];
                                   
                                   [bself.slidingViewController setTopViewController:[controller wrapInNavigationController]];
                                   [bself.slidingViewController resetTopViewAnimated:YES];
                               }
                                        style:UITableViewCellStyleDefault
                                        image:[[UIImage imageNamed:@"28-star"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [self.tableView addCell:cell];
   
    [self.tableView addSectionWithSectionHeaderText:NSLocalizedString(@"Messages", nil)];
    
    cell = [RHTableViewCell cellWithLabelText:NSLocalizedString(@"Inbox", nil)
                              detailLabelText:nil
                               didSelectBlock:^{
                                   
                                   AllThreadsTableViewController *inboxTableViewController = [AllThreadsTableViewController new];
                                   inboxTableViewController.navigationItem.leftBarButtonItem = [self leftMenuButton];
                                   
                                   UISplitViewController *splitViewController = [UISplitViewController new];
                                   [splitViewController setViewControllers:@[[inboxTableViewController wrapInNavigationController], [UINavigationController new]]];
                                   [splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
                                   [splitViewController setDelegate:self];
                                   [bself.slidingViewController setTopViewController:splitViewController];
                                   
                                   [bself.slidingViewController resetTopViewAnimated:YES];
                                   
                               }
                                        style:UITableViewCellStyleDefault
                                        image:[[UIImage imageNamed:@"40-inbox"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [self.tableView addCell:cell];
    
    
    [self.tableView addSectionWithSectionHeaderText:nil];
    
    
    cell = [RHTableViewCell cellWithLabelText:NSLocalizedString(@"About", nil)
                              detailLabelText:nil
                               didSelectBlock:^{
                                   
                                   
                                   RHAboutViewController *controller = [[RHAboutViewController alloc] initWithStyle:UITableViewStyleGrouped];
                                   UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                                   
                                  // navController.modalTransitionStyle   = UIModalTransitionStyleFlipHorizontal;
                                   navController.modalPresentationStyle = UIModalPresentationFormSheet;
                                   
                                   [bself presentViewController:navController animated:YES completion:nil];
                                   
                                   [bself.slidingViewController resetTopViewAnimated:YES];
                               }
                                        style:UITableViewCellStyleDefault
                                        image:nil
                                accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    [self.tableView addCell:cell];
    
    
    
    cell = [RHTableViewCell cellWithLabelText:NSLocalizedString(@"Logout", nil)
                              detailLabelText:nil
                               didSelectBlock:^{
                                   [[WSAppDelegate sharedInstance] logout];
                                   [bself.slidingViewController resetTopViewAnimated:YES];
                                   
                               }
                                        style:UITableViewCellStyleDefault
                                        image:nil
                                accessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    [self.tableView addCell:cell];
    
}

-(RHTableView *)tableView {
    if (_tableView == nil) {
        self.tableView = [[RHTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    }
    
    return _tableView;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping;
}


-(RHBarButtonItem *)leftMenuButton {
    return [RHBarButtonItem itemWithImage:[UIImage imageNamed:@"hamburger"] block:^{
        [self.slidingViewController resetTopViewAnimated:YES];
        [self.slidingViewController anchorTopViewToRightAnimated:YES];
    }];
}

-(void)loadView {
    self.tableView = [[RHTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.view = self.tableView;
}

-(HostMapViewController *)hostMapViewController {
    if (_hostMapViewController == nil) {
        self.hostMapViewController = [[HostMapViewController alloc] initWithNibName:@"HostMapViewController" bundle:nil];
        [_hostMapViewController.navigationItem setLeftBarButtonItem:[self leftMenuButton]];
    }
    
    return _hostMapViewController;
}



#pragma mark -
#pragma mark UISplitViewControllerDelegate
- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if ([secondaryViewController isKindOfClass:[UIViewController class]]) {
        // If the detail controller doesn't have an item, display the primary view controller instead
        return YES;
    }
    
    return NO;
    
}




#pragma mark -

@end