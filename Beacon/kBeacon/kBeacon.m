//
//  kBeacon.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import "kBeacon.h"

#define maxBeaconReagionNum 20


@interface kBeacon()
@property (nonatomic) CLLocationManager *locationManager;
@end


@implementation kBeacon

+ (kBeacon*)sharedInstance {
	
    static kBeacon *sharedSingleton;
	static dispatch_once_t once;
    
	dispatch_once( &once, ^{
        sharedSingleton = [[kBeacon alloc] initSharedInstance];
    });
    
    return sharedSingleton;
}

- (id)initSharedInstance {
    self = [super init];
    
    if(self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _monitoringStatus = kBeaconMonitoringStatusDisabled;
        
        _regions = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (BOOL)isMonitoringAvailableForClass
{
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
         NSLog(@"[CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] is NOT available");
        return NO;
    }
    
    // NotDetermined、Authorized以外（つまりDenied、Restricted）の時は、
    // 設定画面で位置情報サービスをオンすることをうながすAlertを表示する
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (!((status == kCLAuthorizationStatusNotDetermined) ||
          (status == kCLAuthorizationStatusAuthorized))) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"Alert Location Service Disabled", nil)
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"OK", nil] show];
        NSLog(@"CLAuthorizationStatus is NOT available");
        return NO;
    }

    return YES;
}

- (void)startMonitoring {
    if(_monitoringStatus == kBeaconMonitoringStatusMonitoring) {
        NSLog(@"Monitoring has been started");
        return;
    }
        
    if(![self isMonitoringAvailableForClass]) {
        return;
    }
 
    NSLog(@"Start monitoring");
    for (kBeaconRegion *region in _regions) {
        // Beaconによる計測を開始
        [_locationManager startMonitoringForRegion:region];
        
        
        [_locationManager requestStateForRegion:region];
    }
    
    _monitoringStatus = kBeaconMonitoringStatusMonitoring;
}

- (void)stopMonitoring {
    if(_monitoringStatus != kBeaconMonitoringStatusMonitoring) {
        return;
    }

    NSLog(@"Stop monitoring");
    for (kBeaconRegion *region in _regions) {
        [_locationManager stopMonitoringForRegion:region];
    }
    
    _monitoringStatus = kBeaconMonitoringStatusStopped;
}

- (void)startRangingBeaconsInRegion:(kBeaconRegion *)region
{
    NSLog(@"startRanging");
    [_locationManager startRangingBeaconsInRegion:region];
}

- (void)stopRangingBeaconsInRegion:(kBeaconRegion *)region
{
    NSLog(@"stopRanging");
    [_locationManager stopRangingBeaconsInRegion:region];
}

- (void)updateMonitoringStatus
{
    kBeaconMonitoringStatus currentStatus = self.monitoringStatus;
    kBeaconMonitoringStatus newStatus = [self getUpdatedMonitoringStatus];
    
    if (currentStatus != newStatus) {
        self.monitoringStatus = newStatus;
        if ([_delegate respondsToSelector:@selector(didUpdateMonitoringStatus:)]) {
            [_delegate didUpdateMonitoringStatus:self.monitoringStatus];
        }
    }
}

- (kBeaconMonitoringStatus)getUpdatedMonitoringStatus
{
    if (! [self isMonitoringAvailableForClass]) {
        return kBeaconMonitoringStatusDisabled;
    }
    if(_monitoringStatus == kBeaconMonitoringStatusMonitoring) {
        return kBeaconMonitoringStatusMonitoring;
    }
    
    return kBeaconMonitoringStatusStopped;
}

#pragma mark Region Management
- (kBeaconRegion *)addRegion:(NSString *)UUIDString identifier:(NSString *)identifier {
    if([_regions count] >= maxBeaconReagionNum) {
        NSLog(@"Can't add region any more");
        return nil;
    }
    
    kBeaconRegion *region = [[kBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:identifier];
    [self.regions addObject:region];
    return region;
}

- (kBeaconRegion *)addRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier {
    if([_regions count] >= maxBeaconReagionNum) {
        NSLog(@"Can't add region any more");
        return nil;
    }
    
    kBeaconRegion *region = [[kBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major identifier:identifier];
    [self.regions addObject:region];
    return region;
}

- (kBeaconRegion *)addRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier {
    if([_regions count] >= maxBeaconReagionNum) {
        NSLog(@"Can't add region any more");
        return nil;
    }
    
    kBeaconRegion *region = [[kBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major minor:minor identifier:identifier];
    [self.regions addObject:region];
    return region;
}

- (void)removeRegion:(kBeaconRegion *)region {
    int i = 0;
    for (CLBeaconRegion* c in [_regions copy]) {
        if ([c.proximityUUID.UUIDString isEqualToString:region.proximityUUID.UUIDString] &&
            [c.identifier isEqualToString:region.identifier] &&
            c.major == region.major &&
            c.minor == region.minor) {
            [self.regions removeObjectAtIndex:i];
        }
        else {
            ++i;
        }
    }
}

- (void)removeAllRegions {
    [self stopMonitoring];
    [self.regions removeAllObjects];
}

- (kBeaconRegion *)findRegion:(CLBeaconRegion *)region
{
    for (kBeaconRegion* c in _regions) {
        if ([c.proximityUUID.UUIDString isEqualToString:region.proximityUUID.UUIDString] &&
            [c.identifier isEqualToString:region.identifier] &&
            c.major == region.major &&
            c.minor == region.minor) {
            return c;
        }
    }
    return nil;
}

- (void)enterRegion:(CLBeaconRegion *)region
{
    NSLog(@"enterRegion called");
    
    kBeaconRegion *kRegion = [self findRegion:region];
    if (!kRegion)
        return;
    
    // Already in the region.
    if (kRegion.hasEntered)
        return;
    
    // When ranging is enabled, start ranging.
    if (kRegion.rangingEnabled)
        [self startRangingBeaconsInRegion:kRegion];
    
    // Mark as entered.
    kRegion.hasEntered = YES;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:kRegion];
    }
}

- (void)exitRegion:(CLBeaconRegion *)region
{
    NSLog(@"exitRegion called");
    
    kBeaconRegion *kRegion = [self findRegion:region];
    if (!kRegion)
        return;
    
    if (!kRegion.hasEntered)
        return;
    
    if (kRegion.rangingEnabled)
        [self stopRangingBeaconsInRegion:kRegion];
    
    kRegion.hasEntered = NO;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:kRegion];
    }
}


#pragma mark - CLLocationManagerDelegate methods
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"didStartMonitoringForRegion:%@", region.identifier);
  
    // 非同期に実行し、CLLocationManagerDelegateに結果を配送する
    // （locationManager:didDetermineState:forRegion:メソッド要実装）
    [_locationManager requestStateForRegion:region];
}

// Beacon 領域への入りのイベントをハンドリングする
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Enter Region:%@", region.identifier);
    
    // Beaconとの距離測定を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self startRangingBeaconsInRegion:(kBeaconRegion *)region];
    }
}

// Beacon 領域からの出のイベントをハンドリングする
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Exit Region:%@", region.identifier);
    
    // Beaconの距離測定を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self stopRangingBeaconsInRegion:(kBeaconRegion *)region];
    }
}

// 領域に関する状態を取得する
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *statusMessage;
    switch (state) {
        case CLRegionStateInside:
            NSLog(@"state is CLRegionStateInside");
            //[self sendLocalNotificationForMessage:@"CLRegionStateInside"];
            statusMessage = @"CLRegionStateInside";
            
            // 領域内にいるので、測距を開始する
            /*
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            }
             */
            [self enterRegion:(CLBeaconRegion *)region];
            break;
        case CLRegionStateOutside:
            NSLog(@"state is CLRegionStateOutside");
            statusMessage = @"CLRegionStateOutside";
            break;
        case CLRegionStateUnknown:
            NSLog(@"state is CLRegionStateUnknown");
            statusMessage = @"CLRegionStateUnknown";
            [self exitRegion:(CLBeaconRegion *)region];
            break;
        default:
            NSLog(@"state is UNKNOWN");
            statusMessage = @"UNKNOWN";
            [self exitRegion:(CLBeaconRegion *)region];
            break;
    }
    
    NSLog(@"didDetermineState:%@(%@)", statusMessage, region.identifier);
}


// Beaconの距離測定イベントをハンドリングする
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    kBeaconRegion *kRegion = [self findRegion:region];
    if (!kRegion)
        return;
    
    kRegion.beacons = beacons;
    
    if ([_delegate respondsToSelector:@selector(didRangeBeacons:)]) {
        [_delegate didRangeBeacons:kRegion];
    }


    /*
    if (beacons.count > 0) {
        // 最も距離の近いBeaconについて処理をする
        CLBeacon *nearestBeacon = beacons.firstObject;
        NSString *rangeMessage;
        
        // Beaconの距離でメッセージを変える
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                rangeMessage = @"Range Immediate";
                break;
            case CLProximityNear:
                rangeMessage = @"Range Near";
                break;
            case CLProximityFar:
                rangeMessage = @"Range Far";
                break;
            default:
                rangeMessage = @"Range Unknown";
                break;
        }
        
        NSLog(@"didRangeBeacons:%@(%@)", rangeMessage, region.identifier);
    }
     */
}

// 計測に失敗
- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
//    [NSLog(@"rangingBeaconsDidFailForRegion:%@(%@)", region.identifier, error);
    
    kBeaconRegion *r = [self findRegion:region];
    if (!r) {
        return;
    }
    
    [self stopRangingBeaconsInRegion:r];
}



@end