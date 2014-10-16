//
//  HttpRequest.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import "HttpRequest.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPSessionManager.h"

#define requestURL @"http://pacific-eyrie-5378.herokuapp.com/api/v1/gps";


@interface HttpRequest ()<NSURLConnectionDataDelegate>
@end

@implementation HttpRequest

+ (HttpRequest*)sharedInstance {
	
    static HttpRequest *sharedSingleton;
	static dispatch_once_t once;
    
	dispatch_once( &once, ^{
        sharedSingleton = [[HttpRequest alloc] initSharedInstance];
    });
    
    return sharedSingleton;
}

- (id)initSharedInstance {
    self = [super init];
    
    if(self) {
    }
    
    return self;
}


- (void)send:(kGpsData*)gpsdata
{
    NSURL* url = [NSURL URLWithString:@"http://pacific-eyrie-5378.herokuapp.com/api/v1/gps"];
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *params = [NSString stringWithFormat:@"device_id=%@&device_token=%@&latitude=%.6f&longitude=%.6f", gpsdata.device_id, gpsdata.device_token,gpsdata.latitude, gpsdata.longitude];
    
    NSData* data = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                // 完了時の処理
                                                [session invalidateAndCancel];
                                            }];
    
    [task resume];
}


- (void)send2:(kGpsData*)gpsdata
{
    if(gpsdata == nil) {
        NSLog(@"Error: gpsdata was nil");
        return;
    }

    NSString *lat = [NSString stringWithFormat:@"%+.6f", gpsdata.latitude];
    NSString *lng = [NSString stringWithFormat:@"%+.6f", gpsdata.longitude];
    NSDictionary *params = @{@"device_id": gpsdata.device_id,
                             @"device_token": gpsdata.device_token,
                             @"latitude": lat,
                             @"longitude": lng};

    /*
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://pacific-eyrie-5378.herokuapp.com/api/v1/gps" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
     */

    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setAllowInvalidCertificates:YES];
    
    AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
    [operationManager setSecurityPolicy:policy];
    operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
    operationManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operationManager POST:@"http://pacific-eyrie-5378.herokuapp.com/api/v1/gps"
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       NSLog(@"JSON: %@", [responseObject description]);
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       NSLog(@"Error: %@", [error description]);
                   }
     ];
}

@end