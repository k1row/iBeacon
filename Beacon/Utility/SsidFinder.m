//
//  SsidFinder.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/05/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import "SsidFinder.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreFoundation/CoreFoundation.h>

@interface SsidFinder ()
@end


@implementation SsidFinder

- (NSString *)getCurrentWifiName
{
    NSString *wifiName = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            wifiName = [dict valueForKey:@"SSID"];
        }
    }
    NSLog(@"wifiName:%@", wifiName);
    return wifiName;
}

- (id)fetchSSIDInfo {
    
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    NSDictionary *info = nil;
    NSString *ifnam = @"";
    for (ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@", [info valueForKey:@"SSID"]);
        if ([info allKeys] == nil) {
        }

        //NSLog(@"%@ => %@", ifnam, info);
        //if (info && [info count]) { break; }
    }
    /*
    if ([info count] >= 1 && [ifnam caseInsensitiveCompare:prevSSID] !=  NSOrderedSame) {
        // Trigger some event
        prevSSID = ifnam;
    }
     */

    return info;
}

@end
