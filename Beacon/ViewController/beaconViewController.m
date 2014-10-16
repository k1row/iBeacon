//
//  beaconViewController.m
//  Beacon
//
//  Created by Keiichiro Nagashima on 2014/06/02.
//  Copyright (c) 2014年 Keiichiro Nagashima. All rights reserved.
//

#import "beaconViewController.h"
#import "kBeacon.h"

#define kBeaconUUID    @"00000000-55A6-1001-B000-001C4D8F0DE1"
#define kIdentifier    @"jp.k16.beaconregion"


@interface beaconViewController ()<kBeaconDelegate, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) kBeacon *beacon;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *monitoringButton;

@end

@implementation beaconViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    
    _beacon = [kBeacon sharedInstance];
    _beacon.delegate = self;
    kBeaconRegion *region = [_beacon addRegion:kBeaconUUID identifier:kIdentifier];;
    if (region) {
        region.rangingEnabled = YES;
    }

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    _monitoringButton.layer.borderColor = [UIColor grayColor].CGColor;
    _monitoringButton.layer.borderWidth = 1.0f;
    _monitoringButton.layer.cornerRadius = 7.5f;

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Manage monitoring
- (IBAction)pushedStartMonitoringBtn:(id)sender {
    NSLog(@"pushedStartMonitoringBtn");
    
    if (_beacon.monitoringStatus != kBeaconMonitoringStatusMonitoring) {
        [_beacon startMonitoring];
    } else if (_beacon.monitoringStatus == kBeaconMonitoringStatusMonitoring) {
        [_beacon stopMonitoring];
    }
}

- (void)enterRegionNotification:(kBeaconRegion *)region
{
    // LocalNotification.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"Entered to %@", region.identifier];
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

- (void)exitRegionNotification:(kBeaconRegion *)region
{
    // LocalNotification.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"Exit from %@", region.identifier];
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

- (void)didUpdateRegionEnterOrExit:(kBeaconRegion *)region
{
    if (region.hasEntered) {
        NSLog(@"didUpdateRegionEnterOrExit: entered");
        [self enterRegionNotification:region];
    } else {
        NSLog(@"didUpdateRegionEnterOrExit: exit");
        [self exitRegionNotification:region];
    }
    [_tableView reloadData];
}


#pragma mark ESBeaconDelegate
- (void)didUpdateMonitoringStatus:(kBeaconMonitoringStatus)status
{
    switch (status) {
        case kBeaconMonitoringStatusDisabled:
            [_monitoringButton setTitle:@"Disabled" forState:UIControlStateNormal];
            _monitoringButton.enabled = NO;
            break;
        case kBeaconMonitoringStatusStopped:
            [_monitoringButton setTitle:@"Start Monitoring" forState:UIControlStateNormal];
            _monitoringButton.enabled = YES;
            break;
        case kBeaconMonitoringStatusMonitoring:
            [_monitoringButton setTitle:@"Monitoring (Press to Stop)" forState:UIControlStateNormal];
            _monitoringButton.enabled = YES;
            break;
    }
    
    [_tableView reloadData];
}

- (void)didRangeBeacons:(kBeaconRegion *)region
{
    if (!region.beacons) {
        NSLog(@"didRangeBeacons: count 0");
    } else {
        NSLog(@"didRangeBeacons: count %lu", (unsigned long)[region.beacons count]);
    }
    [_tableView reloadData];
}


#pragma mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_beacon.regions count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    kBeaconRegion *region = [_beacon.regions objectAtIndex:section];
    if (region) {
        if (region.beacons == nil) {
            return 0;
        } else {
            return [region.beacons count];
        }
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell= [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];
    kBeaconRegion *region = [_beacon.regions objectAtIndex:indexPath.section];
    if (region && region.beacons) {
        CLBeacon *beacon = [region.beacons objectAtIndex:indexPath.row];
        if (beacon) {
            UILabel *identifierLabel = (UILabel *)[cell viewWithTag:1];
            UILabel *UUIDLabel = (UILabel *)[cell viewWithTag:2];
            UILabel *majorLabel = (UILabel *)[cell viewWithTag:3];
            UILabel *minorLabel = (UILabel *)[cell viewWithTag:4];
            UILabel *RSSILabel = (UILabel *)[cell viewWithTag:5];
            UILabel *accuracyLabel = (UILabel *)[cell viewWithTag:6];
            UILabel *proximityLabel = (UILabel *)[cell viewWithTag:7];
            
            identifierLabel.text = region.identifier;
            UUIDLabel.adjustsFontSizeToFitWidth = YES;
            UUIDLabel.text = region.proximityUUID.UUIDString;
            majorLabel.text = [NSString stringWithFormat:@"major %@", beacon.major];
            minorLabel.text = [NSString stringWithFormat:@"minor %@", beacon.minor];
            RSSILabel.text = [NSString stringWithFormat:@"RSSI: %ld", (long)beacon.rssi];
            accuracyLabel.text = [NSString stringWithFormat:@"Accuracy: %f", beacon.accuracy];
            switch (beacon.proximity) {
                case CLProximityUnknown:
                    proximityLabel.text = @"Proximity: Unknown";
                    break;
                case CLProximityImmediate:
                    proximityLabel.text = @"Proximity: Immediate";
                    break;
                case CLProximityNear:
                    proximityLabel.text = @"Proximity: Near";
                    break;
                case CLProximityFar:
                    proximityLabel.text = @"Proximity: Far";
                    break;
            }
        }
    }
    
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
