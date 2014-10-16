//
//  kBeaconRegion.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import "kBeaconRegion.h"

@implementation kBeaconRegion

- (id)init
{
    self = [super init];
    if (self) {
    }
    
    _rangingEnabled = NO;
    _hasEntered = NO;
    _isRanging = NO;
    _beacons = nil;
    return self;
}

@end
