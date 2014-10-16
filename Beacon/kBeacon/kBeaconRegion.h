//
//  kBeaconRegion.h
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#define kBeaconRegionFailCountMax   3

@interface kBeaconRegion : CLBeaconRegion
@property (nonatomic) BOOL rangingEnabled;
@property (nonatomic) BOOL hasEntered;
@property (nonatomic) BOOL isRanging;
@property (nonatomic) NSArray *beacons;
@end
