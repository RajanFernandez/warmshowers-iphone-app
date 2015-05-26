//
//  TrackMyTourRequest.m
//  TrackMyTour
//
//  Created by Christopher Meyer on 1/7/10.
//  Copyright 2010 Red House Consulting GmbH. All rights reserved.
//

#import "WSRequests.h"
#import "WSAppDelegate.h"
#import "Host.h"
#import "MKMapView+Utils.h"
#import "Feedback.h"
#import "Thread.h"
#import "WSHTTPClient.h"

@implementation WSRequests


+(void)loginWithUsername:(NSString *)username
                password:(NSString *)password
                 success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                 failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    [[WSHTTPClient sharedHTTPClient] deleteCookies];
    
    NSDictionary *params = @{@"username" : username, @"password" : password};
    
    [[WSHTTPClient sharedHTTPClient] POST:@"/services/rest/user/login" parameters:params success:success failure:failure];
}

+(void)requestWithMapView:(MKMapView *)mapView {
    
    if ([[WSAppDelegate sharedInstance] isLoggedIn] == NO) {
        return;
    }
    
    bounds b = [mapView fetchBounds];
    
    // [[WSHTTPClient sharedHTTPClient] cancelAllHTTPOperationsWithMethod:@"POST" path:path];
    [[WSHTTPClient sharedHTTPClient] cancelAllOperations];
    
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithDouble:b.minLatitude], @"minlat",
                            [NSNumber numberWithDouble:b.maxLatitude], @"maxlat",
                            [NSNumber numberWithDouble:b.minLongitude], @"minlon",
                            [NSNumber numberWithDouble:b.maxLongitude], @"maxlon",
                            [NSNumber numberWithDouble:b.centerLatitude], @"centerlat",
                            [NSNumber numberWithDouble:b.centerLongitude], @"centerlon",
                            [NSNumber numberWithInteger:kMaxResults], @"limit",
                            nil];
    
    [[WSHTTPClient sharedHTTPClient] POST:@"/services/rest/hosts/by_location" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSArray *hosts = [responseObject objectForKey:@"accounts"];
        
        for (NSDictionary *dict in hosts) {
            
            NSString *hostidstring = [dict objectForKey:@"uid"];
            NSNumber *hostid = [NSNumber numberWithInteger:[hostidstring integerValue]];
            
            Host *host = [Host hostWithID:hostid];
            
            host.name = [dict objectForKey:@"name"];
            host.street = [dict objectForKey:@"street"];
            host.city = [dict objectForKey:@"city"];
            host.province = [dict objectForKey:@"province"];
            host.postal_code = [dict objectForKey:@"postal_code"];
            host.country = [dict objectForKey:@"country"];
            
            host.last_updated = [NSDate date];
            host.notcurrentlyavailable = [NSNumber numberWithInt:0];
            
            NSString *latitude = [dict objectForKey:@"latitude"];
            NSString *longitude = [dict objectForKey:@"longitude"];
            
            host.latitude = [NSNumber numberWithDouble:[latitude doubleValue]];
            host.longitude = [NSNumber numberWithDouble:[longitude doubleValue]];
        }
        
        [Host commit];
    } failure:nil];
}


+(void)hostDetailsWithHost:(Host *)host {
    
    if ([[WSAppDelegate sharedInstance] isLoggedIn] == NO) {
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"/services/rest/user/%i", [host.hostid intValue]];
    
    [[WSHTTPClient sharedHTTPClient] cancelAllOperations];
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    [[WSHTTPClient sharedHTTPClient] GET:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //  NSDictionary *user = responseObject;
        
        
        [Host fetchOrCreate:responseObject];
        
        /*
         NSNumber *hostid = [user objectForKey:@"uid"];
         
         Host *host = [Host hostWithID:hostid];
         
         host.bed = [NSNumber numberWithInt:[[user objectForKey:@"bed"] intValue]];
         host.bikeshop = [user objectForKey:@"bikeshop"];
         host.campground = [user objectForKey:@"campground"];
         host.city = [user objectForKey:@"city"];
         
         NSString *comments = [user objectForKey:@"comments"];
         host.comments = [comments stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
         
         host.country = [user objectForKey:@"country"];
         host.food = [NSNumber numberWithInt:[[user objectForKey:@"food"] intValue]];
         host.fullname = [user objectForKey:@"fullname"];
         host.homephone = [user objectForKey:@"homephone"];
         host.mobilephone = [user objectForKey:@"mobilephone"];
         host.kitchenuse = [NSNumber numberWithInt:[[user objectForKey:@"kitchenuse"] intValue]];
         host.laundry = [NSNumber numberWithInt:[[user objectForKey:@"laundry"] intValue]];
         host.lawnspace = [NSNumber numberWithInt:[[user objectForKey:@"lawnspace"] intValue]];
         host.maxcyclists = [NSNumber numberWithInt:[[user objectForKey:@"maxcyclists"] intValue]];
         host.motel = [user objectForKey:@"motel"];
         host.name = [user objectForKey:@"name"];
         host.notcurrentlyavailable = [NSNumber numberWithInteger:[[user objectForKey:@"notcurrentlyavailable"] intValue]];
         // TEST
         // host.notcurrentlyavailable = @YES;
         host.postal_code = [user objectForKey:@"postal_code"];
         host.province = [user objectForKey:@"province"];
         host.sag = [NSNumber numberWithInt:[[user objectForKey:@"sag"] intValue]];
         host.shower = [NSNumber numberWithInt:[[user objectForKey:@"shower"] intValue]];
         host.storage = [NSNumber numberWithInt:[[user objectForKey:@"storage"] intValue]];
         host.street = [user objectForKey:@"street"];
         host.preferred_notice = [user objectForKey:@"preferred_notice"];
         
         NSTimeInterval last_login_int = [[user objectForKey:@"login"] doubleValue];
         host.last_login = [NSDate dateWithTimeIntervalSince1970:last_login_int];
         
         NSTimeInterval member_since = [[user objectForKey:@"created"] doubleValue];
         host.member_since = [NSDate dateWithTimeIntervalSince1970:member_since];
         
         host.last_updated_details = [NSDate date];
         */
        [Host commit];
        
        [SVProgressHUD dismiss];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)[task response];
        
        NSInteger statusCode = [response statusCode];
        
        // 404 not found (page doesn't exist anymore)
        if ( statusCode == 404 ) {
            [host setNotcurrentlyavailable:[NSNumber numberWithBool:YES]];
            [Host commit];
        }
        [SVProgressHUD dismiss];
    }];
}


+(void)hostFeedbackWithHost:(Host *)host {
    
    if ([[WSAppDelegate sharedInstance] isLoggedIn] == NO) {
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"/user/%i/json_recommendations", [host.hostid intValue]];
    
    [[WSHTTPClient sharedHTTPClient] GET:path
                              parameters:nil
                                 success:^(NSURLSessionDataTask *task, id responseObject) {

                                         [host purgeFeedback];
                                         
                                         NSArray *recommendations = [responseObject objectForKey:@"recommendations"];
                                         
                                         for (NSDictionary *feedback in recommendations) {
                                             
                                             NSDictionary *dict = [feedback objectForKey:@"recommendation"];
                                             
                                             NSString *snid = [dict objectForKey:@"nid"];
                                             NSString *recommender = [dict objectForKey:@"fullname"];
                                             NSString *body = [[dict objectForKey:@"body"] trim];
                                             NSString *hostOrGuest = [dict objectForKey:@"field_guest_or_host_value"];
                                             NSNumber *recommendationDate = [dict objectForKey:@"field_hosting_date_value"];
                                             
                                             NSNumber *nid = [NSNumber numberWithInteger:[snid integerValue]];
                                             NSDate *rDate = [NSDate dateWithTimeIntervalSince1970:[recommendationDate doubleValue]];
                                             
                                             Feedback *feedback = [Feedback feedbackWithID:nid];
                                             [feedback setBody:body];
                                             [feedback setFullname:recommender];
                                             [feedback setHostOrGuest:hostOrGuest];
                                             [feedback setDate:rDate];
                                             
                                             [host addFeedbackObject:feedback];
                                         }
                                         
                                         [Feedback commit];
                                     
                                 }
                                 failure:^(NSURLSessionDataTask *task, NSError *error) {
                                 }];
}


+(void)searchHostsWithKeyword:(NSString *)keyword {
    NSString *path = @"/services/rest/hosts/by_keyword";
    
    NSDictionary *parms = @{
                            @"keyword" : keyword,
                            @"limit" : @10,
                            @"page" : @0
                            };
    
    [[WSHTTPClient sharedHTTPClient] POST:path
                               parameters:parms
                                  success:^(NSURLSessionDataTask *task, id responseObject) {
                                      
                                      NSArray *hosts = [[responseObject objectForKey:@"accounts"] allObjects];
                                      async({
                                          for (NSDictionary *dict in hosts) {
                                              [Host fetchOrCreate:dict];
                                          }
                                          
                                          [Host commit];
                                      });
                                      
                                  }
                                  failure:^(NSURLSessionDataTask *task, NSError *error) {
                                      
                                  }];
    
}


+(void)refreshThreadsSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    NSString *path = @"/services/rest/message/get";
    
    [[WSHTTPClient sharedHTTPClient] POST:path parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        async({
            NSArray *all_ids = [responseObject pluck:@"thread_id"];
            
            [Thread deleteWithPredicate:[NSPredicate predicateWithFormat:@"NOT (threadid IN %@)", all_ids]];
            
            for (NSDictionary *dict in responseObject) {
                
                NSNumber *threadid = @([[dict objectForKey:@"thread_id"] intValue]);
                NSString *subject = [dict objectForKey:@"subject"];
                NSDictionary *participant = [[dict objectForKey:@"participants"] firstObject];
                NSNumber *is_new= @([[dict objectForKey:@"is_new"] intValue]);
                NSNumber *count = @([[dict objectForKey:@"count"] intValue]);
                
                Thread *thread = [Thread newOrExistingEntityWithPredicate:[NSPredicate predicateWithFormat:@"threadid=%d", [threadid intValue]]];
                
                [thread setThreadid:threadid];
                [thread setSubject:subject];
                [thread setIs_new:is_new];
                [thread setCount:count];
                
                NSNumber *hostid = @([[participant objectForKey:@"uid"] intValue]);
                NSString *name = [participant objectForKeyedSubscript:@"name"];
                
                Host *host = [Host hostWithID:hostid];
                [host setName:name];
                [thread setUser:host];
            }
            
            [Thread commit];
        });
        
        if (success) {
            success(task, responseObject);
        }
        
    } failure:failure];
    
}




@end