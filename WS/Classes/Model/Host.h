//
//  Host.h
//  WS
//
//  Created by Christopher Meyer on 10/16/10.
//  Copyright 2010 Red House Consulting GmbH. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "_Host.h"

@interface Host : _Host<MKAnnotation> {
	CLLocationCoordinate2D coordinate;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

+(Host *)hostWithID:(NSNumber *)hostID;
+(Host *)fetchOrCreate:(NSDictionary *)dict;
+(NSArray *)hostsClosestToLocation:(CLLocation *)location withLimit:(int)limit;
+(NSString *)trimmedPhoneNumber:(NSString *)phoneNumber;

-(NSString *)title;
-(NSString *)subtitle;

-(void)updateDistanceFromLocation:(CLLocation *)location;

-(NSString *)infoURL;
-(NSString *)imageURL;
// -(NSString *)contactURL;
-(BOOL)needsUpdate;
-(BOOL)isStale;

-(NSUInteger)pinColour;


-(CLLocation *)location;
-(NSString *)address;

-(void)purgeFeedback;

@end