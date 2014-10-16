//
//  kGpsData.h
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/04.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface kGpsData : NSObject

@property (nonatomic) NSString *device_id;
@property (nonatomic) NSString *device_token;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;

- (kGpsData *)initWithParam:(NSString *)device_id device_token:(NSString *)device_token latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

@end
