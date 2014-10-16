//
//  HttpRequest.h
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kGpsData.h"

@interface HttpRequest : NSObject
+ (HttpRequest *)sharedInstance;
- (void)send:(kGpsData*)gpsdata;
@end