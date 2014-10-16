//
//  kBeacon.h
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "kBeaconRegion.h"


typedef enum {
    kBeaconMonitoringStatusDisabled,
    kBeaconMonitoringStatusStopped,
    kBeaconMonitoringStatusMonitoring
} kBeaconMonitoringStatus;



@protocol kBeaconDelegate <NSObject>
@optional
- (void)didUpdateMonitoringStatus:(kBeaconMonitoringStatus)status;

- (void)didUpdateRegionEnterOrExit:(kBeaconRegion *)region;
- (void)didRangeBeacons:(kBeaconRegion *)region;
@end


@interface kBeacon : NSObject<CLLocationManagerDelegate>

@property (nonatomic) kBeaconMonitoringStatus monitoringStatus;
@property (nonatomic) NSMutableArray *regions;

@property (nonatomic, weak) id<kBeaconDelegate> delegate;

+ (kBeacon *)sharedInstance;
- (void)startMonitoring;
- (void)stopMonitoring;


#pragma mark Region Management
- (kBeaconRegion *)addRegion:(NSString *)UUIDString identifier:(NSString *)identifier;
- (kBeaconRegion *)addRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (kBeaconRegion *)addRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;
- (void)removeRegion:(kBeaconRegion *)region;
- (void)removeAllRegions;

@end