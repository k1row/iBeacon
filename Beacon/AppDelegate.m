//
//  AppDelegate.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/05/01.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "AppDelegate.h"
#import "SsidFinder.h"

#import <Parse/Parse.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"



#ifdef DEBUG
// デバッグ時は全レベルのログを表示する
int ddLogLevel = LOG_LEVEL_DEBUG;
#else
// リリース時はログを表示しない
int ddLogLevel = LOG_LEVEL_OFF;
#endif


@interface AppDelegate()
@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // From Parse.com
    [Parse setApplicationId:@"fem0IR8z9Eq0SOWM0eg4LFyL8T118QGxuWAUCmZy"
                  clientKey:@"geTBBGoT9m3MqZrCxE9cSb47iJGq7NUgl3g6gakI"];
    

    // バッジ、サウンド、アラートをリモート通知対象として登録する
    // (画面にはプッシュ通知許可して良いかの確認画面が出る)
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                    UIRemoteNotificationTypeAlert|
                                                    UIRemoteNotificationTypeSound];

    self.deviceToken = @"xxxxx";

    // Xcodeのコンソールにログを出力する場合は以下を記述する
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // アップルのシステムロガーに送信する
    [DDLog addLogger:[DDASLLogger sharedInstance]];

    [[[SsidFinder alloc] init] fetchSSIDInfo];
    return YES;
}

// プッシュ通知許可登録成功時
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    // 引数で受け取ったデバイストークンから"<>"を取り除き、プロパティに格納する
     NSString *deviceTokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
     
    // デバイストークン中の半角スペースを除去する
    self.deviceToken = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
     
    NSLog(@"%@", self.deviceToken);
}

// プッシュ通知許可登録失敗時
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // エラー・メッセージをログに出力
    NSLog(@"Failed to register for remote notifications: %@", error);
    // プロパティに空文字を設定する
    self.deviceToken = @"";
}

NSString *stringFromDeviceTokenData(NSData *deviceToken)
{
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (int i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    return [token copy];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"Terminated");
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification)
    {
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.repeatInterval = 0;
        notification.alertBody = @"アプリを終了したので自動記録を終了しました。続けるには再度アプリを起動して下さい。";
        notification.alertAction = @"再起動";
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

@end
