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

#import "FavouriteHostTableViewController.h"
#import "WSAppDelegate.h"
#import "Host.h"


@interface FavouriteHostTableViewController()
-(void)updateDistances;
@end

@implementation FavouriteHostTableViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Favourites", nil);
    
    [self updateDistances];
}


-(void)updateDistances {
	CLLocation *current_location = [[WSAppDelegate sharedInstance] userLocation];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray *hosts = [Host fetchWithPredicate:[NSPredicate predicateWithFormat:@"favourite=1 AND notcurrentlyavailable != 1"]];
		
		for (Host *host in hosts) {
			[host updateDistanceFromLocation:current_location];
		}
		
		[Host commit];
	});
}


-(NSArray *)sortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES]];
}

-(NSPredicate *)predicate {
    if (self.searchString) {
        return [NSPredicate predicateWithFormat:@"(notcurrentlyavailable != 1) AND (distance != nil AND favourite=1) AND (comments CONTAINS[cd] %@ OR name CONTAINS[cd] %@ OR fullname CONTAINS[cd] %@ OR city CONTAINS[cd] %@)", self.searchString, self.searchString, self.searchString, self.searchString];
    } else {
        return [NSPredicate predicateWithFormat:@"notcurrentlyavailable != 1 AND favourite=1"];
    }

}

-(NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController == nil) {

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
		[fetchRequest setEntity:[Host entityDescription]];
		[fetchRequest setSortDescriptors:[self sortDescriptors]];
		[fetchRequest setPredicate:[self predicate]];
		
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:[Host managedObjectContextForCurrentThread] 
																			  sectionNameKeyPath:nil 
																					   cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}
    }
	
    return fetchedResultsController;
} 


@end
