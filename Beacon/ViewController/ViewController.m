//
//  ViewController.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/05/01.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"
#import "SsidFinder.h"
#import "HttpRequest.h"
#import "AppDelegate.h"
#import "mapViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <AdSupport/AdSupport.h>
#import <Parse/Parse.h>



@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSUUID *proximityUUID;
@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) CLLocation* currentLocation;


@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) HttpRequest *httpRequest;

@property (weak, nonatomic) IBOutlet UITextField *textIdfa;
@property (weak, nonatomic) IBOutlet UILabel *labelBeaconStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;
@property (weak, nonatomic) IBOutlet UILabel *labelLatitude;
@property (weak, nonatomic) IBOutlet UILabel *labelLongitude;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelWifiSsid;
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.appDelegate = [[UIApplication sharedApplication] delegate];

    /*
    // ビーコンに関する初期設定
    [self initLocationManager];
    
    [self initIdfa];
    
    self.httpRequest = [[HttpRequest alloc] init];
     */
}

- (void)initLocationManager
{
    if([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        // CLLocationManagerの生成とデリゲート設定
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        // 生成したUUIDからNSUUIDを作成
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:@"00000000-55A6-1001-B000-001C4D8F0DE1"];
        
        // CLBeaconRegionを作成
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID identifier:@"jp.k16.beaconregion"];
        
        // いずれもデフォルト設定値
        self.beaconRegion.notifyOnEntry = YES;
        self.beaconRegion.notifyOnExit = YES;
        self.beaconRegion.notifyEntryStateOnDisplay = NO;
        
        // Beaconによる計測を開始
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
        
        // GPS計測向け
        /*
         ・desireAccuracy：位置情報の取得精度の設定です。6種類の中から選択します。
         　kCLLocationAccuracyBestForNavigation：iOS4以降から使用可能です。最高精度。
         　kCLLocationAccuracyBest：iOS3までの最高精度設定でした。
         　kCLLocationAccuracyNearestTenMeters：誤差10mの設定
         　kCLLocationAccuracyHundredMeters：誤差100mの設定
         　kCLLocationAccuracyKilometer：誤差1kmの設定
         　kCLLocationAccuracyThreeKilometers：誤差3kmの設定
         
         ・activityType：ユーザの移動タイプに合わせて位置情報の更新頻度を設定可能です。(iOS6以降から使用可能)
         　CLActivityTypeFitness：ユーザが歩行移動のときに最適
         　CLActivityTypeAutomotiveNavigation：ユーザが車で移動するときに最適
         　CLActivityTypeOtherNavigation：ユーザがボート/電車/飛行機で移動するときに最適
         　CLActivityTypeOther：その他
         
         ・pausesLocationUpdatesAutomatically：位置情報が自動的にOFFになる設定(iOS6以降から使用可能)
         　アプリがBackground起動中に位置情報の更新が15分以上ない場合に自動でGPS起動がOFFになります。NOを設定することで回避できます。
         
         ・distanceFilter：ここで設定した距離以上移動した場合に位置情報を取得する設定
         　単位は[m]です。
           distanceFilterはGPSの精度になります。以下の例では100m距離が移動する毎に位置情報を取得
         */
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationManager.activityType = CLActivityTypeFitness;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        self.locationManager.distanceFilter = 100.0;

        // サービス開始
        [self.locationManager startUpdatingLocation];
    }
}

- (void)initIdfa
{
    if (![self isAdvertisingTrackingEnabled])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Limit Ad Tracking"
                                                        message:@"Your AdvertisingTracking setting is Limit Ad Tracking."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    _textIdfa.text = [self advertisingIdentifier];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Private methods

- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


#pragma mark - CLLocationManagerDelegate methods
// 領域観測が正常に開始されると呼ばれる
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Start Monitoring Region"];

    // 非同期に実行し、CLLocationManagerDelegateに結果を配送する
    // （locationManager:didDetermineState:forRegion:メソッド要実装）
    [self.locationManager requestStateForRegion:self.beaconRegion];
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
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
            }
            break;
        case CLRegionStateOutside:
            NSLog(@"state is CLRegionStateOutside");
            statusMessage = @"CLRegionStateOutside";
            break;
        case CLRegionStateUnknown:
            NSLog(@"state is CLRegionStateUnknown");
            statusMessage = @"CLRegionStateUnknown";
            break;
        default:
            NSLog(@"state is UNKNOWN");
            statusMessage = @"UNKNOWN";
            break;
    }
    
    //[self sendLocalNotificationForMessage:statusMessage];
    _labelBeaconStatus.text = statusMessage;
}

/* Beacon 領域への出入りのイベントをハンドリングする */
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    // ローカル通知
    [self sendLocalNotificationForMessage:@"Enter Region"];
    
    // Beaconとの距離測定を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // ローカル通知
    [self sendLocalNotificationForMessage:@"Exit Region"];
    
    // Beaconの距離測定を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

// Beaconの距離測定イベントをハンドリングする
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        // 最も距離の近いBeaconについて処理をする
        CLBeacon *nearestBeacon = beacons.firstObject;
        NSString *rangeMessage;
        
        // Beaconの距離でメッセージを変える
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                rangeMessage = @"Range Immediate";
                [self callParseMessage];
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
        
        _labelDistance.text = rangeMessage;
        
        if (0) {
          // ローカル通知
          NSString *message = [NSString stringWithFormat:@"major:%@, minor:%@, acccuracy:%f, rssi:%d", nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, nearestBeacon.rssi];
          [self sendLocalNotificationForMessage:[rangeMessage stringByAppendingString:message]];
        }
    }
}

// GPS計測向け
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // 位置情報を取り出す
    CLLocation* location = [locations lastObject];
    self.currentLocation = location;
    
    NSDate* timestamp = location.timestamp;
    
    NSLog(@"緯度 %+.6f, 経度 %+.6f\n, 水平精度 %+.6f\n",
          location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);

    //緯度
    _labelLatitude.text = [NSString stringWithFormat:@"%+.6f", location.coordinate.latitude];
    //経度
    _labelLongitude.text = [NSString stringWithFormat:@"%+.6f", location.coordinate.longitude];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    _labelTime.text = [df stringFromDate:timestamp];
    
    // wifi情報もここで取得する
    _labelWifiSsid.text = [[[SsidFinder alloc] init] getCurrentWifiName];
    
    kGpsData *gps;
    gps.device_id = [self advertisingIdentifier];
    gps.device_token = self.appDelegate.deviceToken;
    gps.latitude = location.coordinate.latitude;
    gps.longitude = location.coordinate.longitude;
    
    [self.httpRequest send:gps];
}

-(void)callParseMessage
{
    // Create our Installation query
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];
    
    // Send push notification to query
    [PFPush sendPushMessageToQueryInBackground:pushQuery
                                   withMessage:@"Hello World!"];
}


- (NSString *) advertisingIdentifier
{
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

- (NSString *) identifierForVendor
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)])
    {
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return @"";
}

- (BOOL)isAdvertisingTrackingEnabled
{
    if (NSClassFromString(@"ASIdentifierManager") &&
        (![[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]))
    {
        return NO;
    }
    return YES;
}

// mapViewControllerにデータを渡す
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    /*
    mapViewController *m = [segue destinationViewController];
    m.currentLocation = self.currentLocation;
     */
}

@end
