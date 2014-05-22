//
//  BeaconManager.m
//  Beacon Hunter
//
//  Created by Dan Murrell on 11/30/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

#import "BeaconManager.h"

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BeaconManager() <CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *searchingBeaconRegion;

@property (nonatomic, strong) NSMutableArray *delegates;

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CLBeaconRegion *advertisingBeaconRegion;
@property (nonatomic, strong) NSDictionary *advertisingPeripheralData;

@end

#pragma mark - Estimote presets
NSString *kEstimoteUUID = @"B9407F30-F5F8-466E-AFF9-25556B57FE6D";
NSString *kEstimoteIdentifier = @"Estimote Sample Region";

static NSInteger const kAdvertisingPower = -59;


@implementation BeaconManager

#pragma mark - Initialize the manager with a beacon region to watch for

- (instancetype)initForiBeaconWithUUID:(NSUUID *)uuid
                            identifier:(NSString *)identifier
{
    return [self initWithBeaconRegion:[[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier]];
}


- (instancetype)initForiBeaconWithUUID:(NSUUID *)uuid
                                 major:(CLBeaconMajorValue)major
                            identifier:(NSString *)identifier
{
    return [self initWithBeaconRegion:[[CLBeaconRegion alloc] initWithProximityUUID:uuid major:major identifier:identifier]];
}


- (instancetype)initForiBeaconWithUUID:(NSUUID *)uuid
                                 major:(CLBeaconMajorValue)major
                                 minor:(CLBeaconMinorValue)minor
                            identifier:(NSString *)identifier
{
    return [self initWithBeaconRegion:[[CLBeaconRegion alloc] initWithProximityUUID:uuid major:major minor:minor identifier:identifier]];
}


- (instancetype)initWithBeaconRegion:(CLBeaconRegion*)region
{
    if ((self = [super init]))
    {
        _filterOutUnknownProximity = YES;
        _delegates = [NSMutableArray array];
        
        if ([CLLocationManager locationServicesEnabled])
        {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            
            _searchingBeaconRegion = region;
            _searchingBeaconRegion.notifyEntryStateOnDisplay = YES;
            
            [_locationManager startMonitoringForRegion:_searchingBeaconRegion];
            [_locationManager requestStateForRegion:_searchingBeaconRegion];
        }
    }
    
    return self;
}


#pragma mark - Initialize for Estimote beacons

- (instancetype)initForEstimote
{
    return [self initForiBeaconWithUUID:EstimoteUUID()
                             identifier:kEstimoteIdentifier];
}


- (instancetype)initForEstimoteWithMajor:(CLBeaconMajorValue)major
{
    return [self initForiBeaconWithUUID:EstimoteUUID()
                                  major:major
                             identifier:kEstimoteIdentifier];
}


- (instancetype)initForEstimoteWithMajor:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor
{
    return [self initForiBeaconWithUUID:EstimoteUUID()
                                  major:major
                                  minor:minor
                             identifier:kEstimoteIdentifier];
}


NSUUID* EstimoteUUID()
{
    return [[NSUUID alloc] initWithUUIDString:kEstimoteUUID];
}


#pragma mark - Stop monitoring for region

- (void)stopMonitoringForBeacon
{
    [self.locationManager stopMonitoringForRegion:self.searchingBeaconRegion];
}


- (void)dealloc
{
    [self stopMonitoringForBeacon];
    [self stopAdvertising];
}


#pragma mark - Manager CLLocatonManagerDelegate delegates

- (void)addDelegate:(id)delegate
{
    if (delegate != nil &&
        [self.delegates containsObject:delegate] == NO &&
        ([delegate conformsToProtocol:@protocol(CLLocationManagerDelegate)] ||
         [delegate conformsToProtocol:@protocol(BeaconManagerDelegate)])) {
            [self.delegates addObject:delegate];
        }
}


- (void)removeDelegate:(id<CLLocationManagerDelegate>)delegate
{
    if (delegate != nil &&
        [self.delegates containsObject:delegate] &&
        ( [delegate conformsToProtocol:@protocol(CLLocationManagerDelegate)] ||
         [delegate conformsToProtocol:@protocol(BeaconManagerDelegate)] )) {
            [self.delegates removeObject:delegate];
        }
}


- (void)clearAllDelegates
{
    self.delegates = [NSMutableArray array];
}


#pragma mark - CBPEripherableManager pass through methods

- (void)startAdvertisingUUID:(NSString *)uuidString
                       major:(CLBeaconMajorValue)majorValue
                       minor:(CLBeaconMinorValue)minorValue
                  identifier:(NSString *)identifier
               measuredPower:(NSNumber *)measuredPower
{
    [self stopAdvertising];

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];

    self.advertisingBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                           major:majorValue
                                                                           minor:minorValue
                                                                      identifier:identifier];

    // Create a dictionary to advertise our beacon region data
    if (measuredPower == nil) {
        measuredPower = @(kAdvertisingPower);
    }
    self.advertisingPeripheralData = [self.advertisingBeaconRegion peripheralDataWithMeasuredPower:measuredPower];

    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:nil];
}


- (void)startAdvertisingEstimoteMajorValue:(CLBeaconMajorValue)majorValue
                                minorValue:(CLBeaconMinorValue)minorValue
                             measuredPower:(NSNumber *)measuredPower
{
    [self startAdvertisingUUID:kEstimoteUUID major:majorValue minor:minorValue identifier:kEstimoteIdentifier measuredPower:measuredPower];
}


- (void)stopAdvertising
{
    if ([self.peripheralManager isAdvertising]) {
        [self.peripheralManager stopAdvertising];
    }
}


#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    if (self.filterOutUnknownProximity) {
        beacons = [self filterOutUnknownProximityBeacons:beacons];
    }

    if ([beacons count] > 0) {
        NSLog(@"BeaconManager: %@ didRangeBeacons: %@ inRegion: %@", manager, beacons, region);

        for (id delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(locationManager:didRangeBeacons:inRegion:)]) {
                [(id<CLLocationManagerDelegate>)delegate locationManager:manager
                                                         didRangeBeacons:beacons
                                                                inRegion:region];
            }
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
    NSLog(@"BeaconManager: %@ rangingBeaconsDidFailForRegion: %@ withError: %@", manager, region, error);

    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(locationManager:rangingBeaconsDidFailForRegion:withError:)]) {
            [(id<CLLocationManagerDelegate>)delegate locationManager:manager
                                      rangingBeaconsDidFailForRegion:region
                                                           withError:error];
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
    NSLog(@"BeaconManager: %@ monitoringDidFailForRegion: %@ withError: %@", manager, region, error);

    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)]) {
            [(id<CLLocationManagerDelegate>)delegate locationManager:manager
                                          monitoringDidFailForRegion:region
                                                           withError:error];
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLBeaconRegion *)region
{
    NSLog(@"BeaconManager: %@ didEnterRegion: %@", manager, region);
    
    [manager startRangingBeaconsInRegion:region];
}


- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLBeaconRegion *)region
{
    NSLog(@"BeaconManager: %@ didExitRegion: %@", manager, region);

    [manager stopRangingBeaconsInRegion:region];
}


- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLBeaconRegion *)region
{
    NSLog(@"BeaconManager: %@ didDetermineState: %ld forRegion: %@", manager, (long)state, region);

    switch (state)
    {
        case CLRegionStateInside:
            [manager startRangingBeaconsInRegion:region];
            break;
            
        case CLRegionStateOutside:
            [manager stopRangingBeaconsInRegion:region];
            break;
            
        case CLRegionStateUnknown:
            break;
    }
}


#pragma mark - CBPeripheralManager delegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"Beacon manager's peripheral did update state: %@", peripheral);

    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"  Powered ON");
        [self.peripheralManager startAdvertising:self.advertisingPeripheralData];
    } else if (peripheral.state == CBPeripheralManagerStatePoweredOff) {
        NSLog(@"  Powered OFF");
        [self.peripheralManager stopAdvertising];
    }

    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(beaconManagerDidStopAdvertising)]) {
            [delegate beaconManagerDidStopAdvertising];
        }
    }
}


- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error
{
    NSLog(@"Beacon manager did start advertising");

    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(beaconManagerDidStartAdvertisingWithError:)]) {
            [delegate beaconManagerDidStartAdvertisingWithError:error];
        }
    }
}


#pragma mark - private implementation

- (NSArray *)filterOutUnknownProximityBeacons:(NSArray *)beacons
{
    NSMutableArray *filteredBeacons = [NSMutableArray array];
    
    for (CLBeacon *beacon in beacons) {
        if (beacon.proximity != CLProximityUnknown) {
            [filteredBeacons addObject:beacon];
        }
    }
    
    return filteredBeacons;
}

@end
