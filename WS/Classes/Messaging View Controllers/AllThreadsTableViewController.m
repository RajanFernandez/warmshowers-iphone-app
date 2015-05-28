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

#import "AllThreadsTableViewController.h"
#import "Thread.h"
#import "Host.h"
#import "SingleThreadTableViewController.h"
#import "WSRequests.h"

static NSString *CellIdentifier = @"ThreadsTableCell";

@interface AllThreadsTableViewController ()

@end


@implementation AllThreadsTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"Inbox", nil)];
    
    [self.tableView registerClass:[RHTableViewCellStyleSubtitleLighterDetail class] forCellReuseIdentifier:CellIdentifier];
    
    self.refreshControl = [RHRefreshControl refreshControlWithBlock:^(RHRefreshControl *refreshControl) {
     
        [WSRequests refreshThreadsSuccess:^(NSURLSessionDataTask *task, id responseObject) {
            [refreshControl endRefreshing];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [refreshControl endRefreshing];
        }];
       
    }];
    
    // refresh on load
    [(RHRefreshControl *)self.refreshControl refresh];
}


-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Thread *thread = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *title = [NSString stringWithFormat:@"%@ (%ld)", thread.subject, (long)[thread.count integerValue]];
    
    
    [cell.textLabel setText:title];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    [cell.detailTextLabel setText:thread.user.title];
    
    /*
     NSArray *participants = [thread.participants allObjects];
    NSArray *names = [participants arrayByPerformingSelector:@selector(title)];
    
    
    
    [cell.detailTextLabel setText:[names componentsJoinedByString:@", "]];
     */
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Thread *thread = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    SingleThreadTableViewController *controller = [[SingleThreadTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [controller setThread:thread];
    
    
    UISplitViewController *split = self.splitViewController;
    
    [split showDetailViewController:[controller wrapInNavigationController] sender:nil];
    
}


-(NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController == nil) {
        NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"threadid" ascending:NO];
        
        NSPredicate *predicate = nil;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[Thread entityDescription]];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort1, nil]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:[Thread managedObjectContextForCurrentThread]
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
        
        fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error: %@", [error localizedDescription]);
        }
        
    }
    
    return fetchedResultsController;
}

@end