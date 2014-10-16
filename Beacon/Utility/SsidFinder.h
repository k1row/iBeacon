//
//  SsidFinder.h
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/05/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SsidFinder : NSObject
-(NSString *)getCurrentWifiName;
- (id)fetchSSIDInfo;
@end
