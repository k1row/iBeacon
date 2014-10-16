//
//  HttpRequest.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import "kGpsData.h"


@interface kGpsData ()
@end

@implementation kGpsData

- (kGpsData *)initWithParam:(NSString *)device_id
               device_token:(NSString *)device_token
               latitude:(CLLocationDegrees)latitude
               longitude:(CLLocationDegrees)longitude {
 
    self = [super init];
    
    if(self) {
        _device_id = device_id;
        _device_token = device_token;
        _latitude = latitude;
        _longitude = longitude;
    }
    
    return self;
}

@end