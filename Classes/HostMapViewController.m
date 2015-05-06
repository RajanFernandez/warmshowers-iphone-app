//
//  MapViewController.m
//  WS
//
//  Created by Christopher Meyer on 10/16/10.
//  Copyright 2010 Red House Consulting GmbH. All rights reserved.
//

#import "HostMapViewController.h"
#import "WSRequests.h"
#import "Host.h"
#import "MKMapView+Utils.h"
#import "MKMapView+ZoomLevel.h"
#import "WSAppDelegate.h"
#import "HostInfoViewController.h"
#import "RHAboutViewController.h"
#import "HostTableViewController.h"
#import "WSHTTPClient.h"

#import "KPAnnotation.h"

@interface HostMapViewController()
@property (nonatomic, strong) KPClusteringController *clusteringController;

@end

@implementation HostMapViewController
#pragma mark -
#pragma mark View lifecycle


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.title = NSLocalizedString(@"Map", nil);
		self.locationUpdated = NO;
		self.hasRunOnce = NO;
	}
	
	return self;
}


-(void)viewDidLoad {
    [super viewDidLoad];
    
	self.lastZoomLevel = [self.mapView zoomLevel];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redrawAnnotation:) name:kShouldRedrawMapAnnotation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationChanged:) name:kAuthenticationStatusChangedNotificationName object:nil];
    
	UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout",nil) style:UIBarButtonItemStylePlain target:self action:@selector(logoutActionSheet:)];
    
	UIBarButtonItem *locateButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ios7-navigate-outline"] style:UIBarButtonItemStylePlain target: self action:@selector(zoomToCurrentLocation:)];
	
	// UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton buttonWithType:UIButtonTypeInfoDark]];
	
	UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStylePlain target:self action:@selector(infoButtonPressed:)];
	
	NSArray *toolbarItems = [NSArray arrayWithObjects:
                             logoutButton,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             infoButton,
                             // [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             locateButton,
                             nil];
	
    // [toolbarItems makeObjectsPerformSelector:@selector(release)];
	[self setToolbarItems:toolbarItems animated:YES];
    
    self.clusteringController = [[KPClusteringController alloc] initWithMapView:self.mapView];
    [self.clusteringController setDelegate:self];
    
    [self redrawAnnotations];
}


-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	// This might be overly complicated.  The IB MapView has the delegate set to nil
	// and the showLocation set to false.  We want everything to be initialized before we
	// start receiving location events.  This following approach ensures we receive just one
	// location update and region change on the map.  Should initiate a single update request,
	// which will also force an authentication check.  Yeah, complicated, but I think it works.
	if (self.hasRunOnce == NO) {
		[self.mapView setDelegate:self];
		[self.mapView setShowsUserLocation:YES];
		
		self.hasRunOnce = YES;
	}
}

-(void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	self.pageCurlImageButton.y = self.navigationController.toolbar.y - self.pageCurlImageButton.height;
}

-(void)logoutActionSheet:(id)sender {
	self.popoverActionsheet = [RHActionSheet actionSheetWithTitle:nil];
	
	[self.popoverActionsheet addDestructiveButtonWithTitle:NSLocalizedString(@"Logout", nil) block:^{
		[[WSAppDelegate sharedInstance] performSelector:@selector(logout)];
        // [[RHAlertView alertWithOKButtonWithTitle:@"Logged Out" message:@"You have been logged out. You will need to login again to continue using the app."] show];
	}];
	
	[self.popoverActionsheet addCancelButtonWithTitle:kCancel];
	[self.popoverActionsheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark -
#pragma mark Fetched results controller

-(NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController == nil) {
		// Create the fetch request for the entity.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		
		// Edit the entity name as appropriate.
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"HostEntity" inManagedObjectContext:[Host managedObjectContextForCurrentThread]];
		[fetchRequest setEntity:entity];
		// [fetchRequest setFetchBatchSize:20];
		// [fetchRequest setFetchLimit:75];
		
		// Edit the sort key as appropriate.
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"last_updated" ascending:NO];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[fetchRequest setSortDescriptors:sortDescriptors];
        
		bounds b = [self.mapView fetchBounds];
        
		// NSPredicate * p = [NSPredicate predicateWithFormat:@"last_updated >= NOW() - 86400", aDate]
		// last_updated >= NOW() - 86400
		// NOW()-86400 <= last_updated
		// NSDate *weekago = [[NSDate date] dateByAddingTimeInterval:-604800];
		
		
		// notcurrentlyavailable=1 means the host is not available.  The value 0 or nil means they are or might be availble.  Only hide if we're certain they are not not available.
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%f < latitude AND latitude < %f AND %f < longitude AND longitude < %f AND notcurrentlyavailable != 1", b.minLatitude, b.maxLatitude, b.minLongitude, b.maxLongitude];
		
		// NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%f < latitude AND latitude < %f AND %f < longitude AND longitude < %f AND last_updated >= %@", b.minLatitude, b.maxLatitude, b.minLongitude, b.maxLongitude, weekago];
		// NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%f < latitude AND latitude < %f AND %f < longitude AND longitude < %f", b.minLatitude, b.maxLatitude, b.minLongitude, b.maxLongitude];
	
        //	[fetchRequest setPredicate:predicate];
        
		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:[Host managedObjectContextForCurrentThread]
																			  sectionNameKeyPath:nil
																					   cacheName:nil];
		[_fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![_fetchedResultsController performFetch:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			// abort();
		}
    }
	
    return _fetchedResultsController;
}

-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [[WSHTTPClient sharedHTTPClient] cancelAllOperations];
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
	
	CLLocation *location = userLocation.location;
	// WSAppDelegate *appDelegate = [WSAppDelegate sharedInstance];
	
	if (location && (self.locationUpdated == NO)) {
		[self.mapView setCenterCoordinate:userLocation.location.coordinate zoomLevel:8 animated:YES];
		self.locationUpdated = YES;
	}
}


// Called when map is moved or zoomed in or out

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    NSArray *visibleAnnotations = [self.mapView visibleAnnotations];
    BOOL animatePin = ([visibleAnnotations count] < 35);
    
    [self.clusteringController refresh:animatePin];
    [WSRequests requestWithMapView:self.mapView];
}

- (BOOL)clusteringControllerShouldClusterAnnotations:(KPClusteringController *)clusteringController {
    return self.mapView.zoomLevel < 14; // Find zoom level that suits your dataset
}

#pragma mark -
#pragma mark Fetched results controller delegate


/*
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	// [self removeAnnotations];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	Host *host = (Host *)anObject;
    
	switch(type) {
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeInsert:
			[self.mapView addAnnotation:host];
			break;
		case NSFetchedResultsChangeDelete:
			[self.mapView removeAnnotation:host];
			break;
            
            // This is ugly.  Causes annotations to flash.
 
            // case NSFetchedResultsChangeUpdate:
             // [self.mapView removeAnnotation:host];
             // [self.mapView addAnnotation:host];
             // break;

	}
}
 */

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ([[[controller managedObjectContext] insertedObjects] count] > 0) {
        [self redrawAnnotations];
    }
}

-(void)zoomToCurrentLocation:(id)sender {
	MKUserLocation *userLocation = [self.mapView userLocation];
	[self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
}

-(void)redrawAnnotations {
    self.fetchedResultsController = nil;
    
    if ([[WSAppDelegate sharedInstance] isLoggedIn]) {
        [self.clusteringController setAnnotations:[self.fetchedResultsController fetchedObjects]];
    }
}

-(void)clusteringController:(KPClusteringController *)clusteringController configureAnnotationForDisplay:(KPAnnotation *)annotation {
    if ([annotation isCluster]) {
        annotation.title = [NSString stringWithFormat:@"%lu hosts", (unsigned long)annotation.annotations.count];
        annotation.subtitle = [NSString stringWithFormat:@"within %.0f meters", annotation.radius];
    } else {
        Host *host = [[annotation annotations] anyObject];
        [annotation setTitle:[host title]];
        [annotation setSubtitle:[host subtitle]];
    }
   //  annotation.subtitle = [NSString stringWithFormat:@"%.0f meters", annotation.radius];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *annotationView = nil;
    
    if ([annotation isKindOfClass:[KPAnnotation class]]) {
        KPAnnotation *kingpinAnnotation = (KPAnnotation *)annotation;
        
        if ([kingpinAnnotation isCluster]) {
            
             annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
            
            if (annotationView == nil) {
                annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:kingpinAnnotation reuseIdentifier:@"cluster"];
            }
            
            annotationView.pinColor = MKPinAnnotationColorRed;

        } else {
            
            Host *host = (Host *)[[kingpinAnnotation annotations] anyObject];

            annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
            
            if (annotationView == nil) {
                annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:kingpinAnnotation reuseIdentifier:@"pin"];
            }
            
            annotationView.pinColor = [host pinColour];
            // annotationView.canShowCallout = YES;
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [button addTarget:self action:@selector(accessoryTapped:) forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = button;
            
            
        }
        
        annotationView.canShowCallout = YES;
        
    }
    
    return annotationView;
}

-(void)accessoryTapped:(id)sender {
	NSArray *annotations = [self.mapView selectedAnnotations];
    
    KPAnnotation *kingpinAnnotation = [annotations firstObject];
	Host *host = [[kingpinAnnotation annotations] anyObject];	
	HostInfoViewController *controller = [[HostInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
	controller.host = host;
	[self.navigationController pushViewController:controller animated:YES];
}

-(void)infoButtonPressed:(id)sender {
	RHAboutViewController *controller = [[RHAboutViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	navController.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[self.navigationController presentViewController:navController animated:YES completion:nil];
}

-(void)authenticationChanged:(id)notification {
    if ([[WSAppDelegate sharedInstance] isLoggedIn]) {
        [self redrawAnnotations];
    } else {
        [self.mapView removeAnnotations:[self.mapView annotations]];
    }
}

-(IBAction)mapTypeSegmentedControl:(UISegmentedControl *)sender {
	switch ([sender selectedSegmentIndex]) {
		case 0:
			self.mapView.mapType = MKMapTypeStandard;
			break;
		case 1:
			self.mapView.mapType = MKMapTypeSatellite;
			break;
		default:
			self.mapView.mapType = MKMapTypeHybrid;
			break;
	}
	
	if ([self.presentedViewController isEqual:self.mapPropertiesViewController]) {
		[self.mapPropertiesViewController dismissViewControllerAnimated:YES completion:nil];
	}
}

-(IBAction)showMapProperties:(id)sender {
    [self presentViewController:self.mapPropertiesViewController animated:YES completion:nil];
}

@end