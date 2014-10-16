//
//  mapViewController.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/06.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "mapViewController.h"
#import <MapKit/MapKit.h>


#pragma mark - GeoFence distance

#define FENCE_1 100.0
#define FENCE_2 500.0
#define FENCE_3 1000.0


#pragma mark - Annotations
@interface CenterAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end

@implementation CenterAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
	if( nil != (self = [super  init]) ){
		self.coordinate = coord;
	}
	return self;
}

@end

@interface CenterAnnotationView : MKAnnotationView
@end

@implementation CenterAnnotationView
- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString*)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if( self ){
		UIImage* image = [UIImage imageNamed:@"target"];
		self.frame = CGRectMake(self.frame.origin.x,self.frame.origin.y,image.size.width,image.size.height);
		self.image = image;
	}
	return self;
}
@end


#pragma mark - mapViewController
@interface mapViewController ()<MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *fenceSwitch;

@end

@implementation mapViewController {
	BOOL _didLoadData;
    BOOL _isMonitoring;

	CLLocationManager *_locationManager;
	CLLocationCoordinate2D _centerLocation;
	CenterAnnotation *_centerAnnotation;
	CLCircularRegion *_regionNearby;
	CLCircularRegion *_regionBlock;
	CLCircularRegion *_regionTown;
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    _didLoadData = NO;

    [self initLocationManager];

    _mapView.delegate = self;
    [_mapView setShowsBuildings:YES];
    [_mapView setShowsPointsOfInterest:YES];
    [_mapView setShowsUserLocation:YES];

    // view に追加
    [self.view addSubview:self.mapView];
}

- (void)initLocationManager
{
    if([CLLocationManager isMonitoringAvailableForClass:[CLRegion class]])
    {

        // CLLocationManagerの生成とデリゲート設定
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;

        // NotDetermined、Authorized以外（つまりDenied、Restricted）の時は、
        // 設定画面で位置情報サービスをオンすることをうながすAlertを表示する
        //
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (!((status == kCLAuthorizationStatusNotDetermined) ||
              (status == kCLAuthorizationStatusAuthorized))) {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:NSLocalizedString(@"Alert Location Service Disabled", nil)
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil] show];
            return;
        }


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

        //_locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.desiredAccuracy =kCLLocationAccuracyBest;
        _locationManager.activityType = CLActivityTypeFitness;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        //_locationManager.distanceFilter = 100.0;
        _locationManager.distanceFilter = kCLDistanceFilterNone;

        // サービス開始
        [_locationManager startUpdatingLocation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
	if(_didLoadData) {
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_centerLocation, (FENCE_3 * 3.0), (FENCE_3 * 3.0));
		[_mapView setRegion:region animated:YES];

		[self setGeofenceAt:_centerLocation];
		[self monitoring:YES];
	}
    else{
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_mapView.userLocation.location.coordinate, (FENCE_3 * 3.0), (FENCE_3 * 3.0));
		[_mapView setRegion:region animated:YES];
	}

    [self setGeofenceAt:_mapView.region.center];
	[self saveData];
	[self monitoring:YES];

    [_mapView setCenterCoordinate:_centerLocation animated:NO];

    // 地図上の中点と縮尺を設定
    MKCoordinateRegion region = _mapView.region;
    region.center = _centerLocation;
    region.span.latitudeDelta = 0.02;
    region.span.longitudeDelta = 0.02;
    [_mapView setRegion:region animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload
{
    [super viewDidUnload];

    [_locationManager stopUpdatingLocation]; // Just in case.
    _locationManager.delegate = nil;
    _locationManager = nil;
}


#pragma mark - GeoFence job
- (void)setGeofenceAt:(CLLocationCoordinate2D)geofenceCenter
{
	[_mapView removeOverlays:_mapView.overlays];

	_centerLocation = geofenceCenter;

	MKCircle *_fenceRange1 = [MKCircle circleWithCenterCoordinate:_centerLocation radius:FENCE_1];
	MKCircle *_fenceRange2 = [MKCircle circleWithCenterCoordinate:_centerLocation radius:FENCE_2];
	MKCircle *_fenceRange3 = [MKCircle circleWithCenterCoordinate:_centerLocation radius:FENCE_3];

	[_mapView addOverlay:_fenceRange1 level:MKOverlayLevelAboveRoads];
	[_mapView addOverlay:_fenceRange2 level:MKOverlayLevelAboveRoads];
	[_mapView addOverlay:_fenceRange3 level:MKOverlayLevelAboveRoads];

	_regionNearby = [[CLCircularRegion alloc] initWithCenter:_fenceRange1.coordinate radius:_fenceRange1.radius identifier:@"nearby"];
	_regionNearby.notifyOnEntry = YES;
	_regionNearby.notifyOnExit  = YES;

	_regionBlock = [[CLCircularRegion alloc] initWithCenter:_fenceRange2.coordinate radius:_fenceRange2.radius identifier:@"nextBlock"];
	_regionBlock.notifyOnEntry = YES;
	_regionBlock.notifyOnExit  = YES;

	_regionTown = [[CLCircularRegion alloc] initWithCenter:_fenceRange3.coordinate radius:_fenceRange3.radius identifier:@"nextTown"];
	_regionTown.notifyOnEntry = YES;
	_regionTown.notifyOnExit  = YES;
}

- (void)monitoring:(BOOL)flag
{
    _isMonitoring = flag;

	if(flag == YES) {
		[_locationManager requestStateForRegion:_regionNearby];
		[_locationManager startMonitoringForRegion:_regionNearby];
		[_locationManager startMonitoringForRegion:_regionBlock];
		[_locationManager startMonitoringForRegion:_regionTown];
    }
	else {
        //[_locationManager stopUpdatingLocation];
        [self clearGeofences];
	}
}

- (void) clearGeofences
{
    NSArray * monitoredRegions = [_locationManager.monitoredRegions allObjects];
    for(CLRegion *region in monitoredRegions) {
        [_locationManager stopMonitoringForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region{

}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"%@",error);
}


// 受信した位置情報イベントの処理
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    location = [locations lastObject];

    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
   	NSLog(@"%d", abs(howRecent));

    // 最も直近のデータが15秒以内であれば有効とみなす
    if (abs(howRecent) < 15) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              location.coordinate.latitude,
              location.coordinate.longitude);
    }

    // 緯度・軽度を設定
    _centerLocation.latitude = location.coordinate.latitude;
    _centerLocation.longitude = location.coordinate.longitude;
}


// 進入イベント 通知
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {

	if([region.identifier isEqualToString:@"nextTown"]) {
        [self showDialog:[NSString stringWithFormat:@"ジオフェンス%.0fm内に入りました", FENCE_3]];
	}
	if([region.identifier isEqualToString:@"nextBlock"]) {
        [self showDialog:[NSString stringWithFormat:@"ジオフェンス%.0fm内に入りました", FENCE_2]];
	}
	if([region.identifier isEqualToString:@"nearby"]) {
        [self showDialog:[NSString stringWithFormat:@"ジオフェンス%.0fm内に入りました", FENCE_1]];
	}
}

// 退出イベント 通知
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {

	if([region.identifier isEqualToString:@"nearby"]) {
        [self showDialog:[NSString stringWithFormat:@"ジオフェンス%.0fmから外に出ました", FENCE_1]];
	}
	if([region.identifier isEqualToString:@"nextBlock"]) {
        [self showDialog:[NSString stringWithFormat:@"ジオフェンス%.0fmから外に出ました", FENCE_2]];
	}
	if([region.identifier isEqualToString:@"nextTown"]) {
        [self showDialog:[NSString stringWithFormat:@"ジオフェンス%.0fmから外に出ました", FENCE_3]];
	}
}

// オーバーレイ描画イベント
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if(_isMonitoring) {
        MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle*)overlay];
        renderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        renderer.lineWidth = 1.0;
        renderer.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
        return (MKOverlayRenderer*)renderer;
    }
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {

	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;

	if ([annotation isKindOfClass:[CenterAnnotation class]]) {
		MKAnnotationView* annotationView = [_mapView  dequeueReusableAnnotationViewWithIdentifier:@"CenterAnnotation"];
		if( annotationView ){
			annotationView.annotation = annotation;
		}
		else{
			annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CenterAnnotation"];
		}
		annotationView.image = [UIImage imageNamed:@"target"];
		return annotationView;
	}

	return nil;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
	if(_centerAnnotation){
		[_mapView removeAnnotation:_centerAnnotation];
	}
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

	if(_centerAnnotation){
		_centerAnnotation.coordinate = _mapView.region.center;
	}
	else {
		_centerAnnotation = [[CenterAnnotation alloc] initWithCoordinate:_mapView.region.center];
	}

	[_mapView addAnnotation:_centerAnnotation];
	NSLog(@"%f,%f", _mapView.region.center.latitude, _mapView.region.center.longitude);
}

- (void)showDialog:(NSString *)str
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Title"
                                                    message:str
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.delegate       = self;
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert show];
}

- (NSNumber*)calculateDistanceInMetersBetweenCoord:(CLLocationCoordinate2D)coord1 coord:(CLLocationCoordinate2D)coord2
{
    NSInteger nRadius = 6371; // Earth's radius in Kilometers
    double latDiff = (coord2.latitude - coord1.latitude) * (M_PI/180);
    double lonDiff = (coord2.longitude - coord1.longitude) * (M_PI/180);
    double lat1InRadians = coord1.latitude * (M_PI/180);
    double lat2InRadians = coord2.latitude * (M_PI/180);
    double nA = pow(sin(latDiff/2), 2) + cos(lat1InRadians) * cos(lat2InRadians) * pow(sin(lonDiff/2), 2);
    double nC = 2 * atan2(sqrt(nA), sqrt(1 - nA));
    double nD = nRadius * nC;

    // convert to meters
    return @(nD * 1000);
}

- (void)saveData
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithDouble:_centerLocation.latitude], @"latitude",
						  [NSNumber numberWithDouble:_centerLocation.longitude], @"longitude",
						  nil
						  ];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:dict forKey:@"GeofenceData"];
}

- (void)loadData
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults dictionaryForKey:@"GeofenceData"];
	if(dict) {
		_didLoadData = YES;
		_centerLocation = CLLocationCoordinate2DMake([[dict valueForKey:@"latitude"] doubleValue], [[dict valueForKey:@"longitude"] doubleValue]);
	}
}

- (IBAction)fenceSwitchvalueChanged:(id)sender {
    UISwitch *sw = sender;
	[self monitoring:sw.on];
}

@end
