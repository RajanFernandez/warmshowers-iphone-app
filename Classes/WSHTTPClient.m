//
//  WSHTTPClient.m
//  WS
//
//  Created by Christopher Meyer on 9/18/12.
//  Copyright (c) 2012 Red House Consulting GmbH. All rights reserved.
//

#import "WSHTTPClient.h"

@implementation WSHTTPClient

+(WSHTTPClient *)sharedHTTPClient {

	static WSHTTPClient *_sharedClient = nil;
	static dispatch_once_t oncePredicate;
	
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[WSHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.warmshowers.org/"]];
		[[_sharedClient reachabilityManager] startMonitoring];
		[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    });
	
    return _sharedClient;
}


-(BOOL)reachable {
	return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

-(void)cancelAllOperations {
    [[self.operationQueue operations] makeObjectsPerformSelector:@selector(cancel)];
}

@end