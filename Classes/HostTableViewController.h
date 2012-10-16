//
//  HostTableViewController.h
//  WS
//
//  Created by Christopher Meyer on 10/26/11.
//  Copyright (c) 2011 Red House Consulting GmbH. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "RHCoreDataTableViewController.h"

@interface HostTableViewController : RHCoreDataTableViewController<UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSString *searchString;
// @property (nonatomic, retain) IBOuUITableViewCell *tempCell;


-(void)updateDistances;

@end