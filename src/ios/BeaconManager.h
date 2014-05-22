//
//  BeaconManager.h
//  Beacon Hunter
//
//  Created by Dan Murrell on 11/30/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/**
 `BeaconManager` is an iBeacon manager that allows multiple objects to react to beacon events while only one monitors for a CLBeaconRegion. It also provides an API for advertising the device as an iBeacon itself.

 ## Creating a BeaconManager
 `BeaconManager` is a single-region object that can take any number of delegates implementing the CLLocationManagerDelegate protocol. The BeaconManager object will create the CLBeaconRegion for you, with you providing the UUID (as a string) and identifier for the region, and optional Major and Minor value.

 `BeaconManager` is also partially-compatible with Estimote beacons. While it does not currently implement Estimote-specific vendor features (such as additional sensors), a BeaconManager object can also be initialized with an Estimote CLBeaconRegion, where you provide only the optional Major and Minor values. `BeaconManager` provides the Estimote standard UUID and Identifier.

 Standard iBeacon profile proximity events are binned into four categories based on estimated proximity:
 - **IMMEDIATE** the beacon is within a couple of inches,
 - **NEAR** the beacon is between a few inches and a couple of feet,
 - **FAR** the beacon is beyond a couple of feet,
 - **UNKNOWN** the beacon has been detected, but the signal is so weak that iOS cannot make a good estimate of proximity.

 Because **unknown** events may or may not be useful based on your application, `BeaconManager` provides a setting (defaults to YES) to automatically filter out these events. You may also filter them manually later.

 `BeaconManager` provides a way to add both CLLocationManagerDelegate objects and BeaconManagerDelegate objects to the delegate list, allowing you to add any number of delegates to receive incoming proximity events.

 Additionally, `BeaconManager` allows you to set a single navigationController to also receive proximity events, in cases where you want only the topViewController to be actively receiving events. It will be checked to ensure it conforms to the CLLocationManagerDelegate or BeaconManagerDelegate protocol.
 */

@protocol BeaconManagerDelegate <NSObject>

@optional

///---------------------------------------
/// @name BeaconManagerDelegate methods
///---------------------------------------

/**
 Notifies the delegate that the BeaconManager has begun advertising as a beacon.

 @param error Any error message resulting from telling `BeaconManager` to start advertising as a beacon. If successful, error will be *nil*. If there is any problem advertising the data, the *error* parameter returns the cause of the failure.
 */

- (void)beaconManagerDidStartAdvertisingWithError:(NSError *)error;

/**
 Notifies the delegate that the BeaconManager has ended advertising as a beacon.
 */

- (void)beaconManagerDidStopAdvertising;

@end


@interface BeaconManager : NSObject

/**
 If set, the top view controller of the navigation controller will automatically receive CLLocationManager delegate methods (if the view controller implements the protocol) and BeaconManagerDelegate methods (if the view controller implements the protocol).
 */
@property (nonatomic, strong) UINavigationController *navigationController;

/**
 If YES, ignore any CLProximityUnknown events.

 By default, this is set to `YES`. If you want to manually filter CLProximityUnknown events based on some additional criteria, set this to `NO` and BeaconManager will forward all beacons ranged regardless of proximity.
 */
@property (nonatomic) BOOL filterOutUnknownProximity;


#pragma mark - Initialize the manager with a beacon region to watch for

/**
 Initialize the manager to watch for an iBeacon with any Major or Minor value

 @param uuidString The unique identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool.
 @param identifier A unique identifier to associate with the returned region object. You use this identifier to differentiate regions within your application. This value must not be nil.
 */
- (instancetype)initForiBeaconWithUUID:(NSUUID *)uuid
                            identifier:(NSString *)identifier;

/**
 Initialize the manager to watch for an iBeacon with a specific Major value and any Minor value

 @param uuidString The unique identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool.
 @param major The major value that you use to identify one or more beacons.
 @param identifier A unique identifier to associate with the returned region object. You use this identifier to differentiate regions within your application. This value must not be nil.
 */
- (instancetype)initForiBeaconWithUUID:(NSUUID *)uuid
                                 major:(CLBeaconMajorValue)major
                            identifier:(NSString *)identifier;

/**
 Initialize the manager to watch for an iBeacon with a specific Major value and Minor value

 @param uuidString The unique identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool.
 @param major The major value that you use to identify one or more beacons.
 @param minor The minor value that you use to identify one or more beacons.
 @param identifier A unique identifier to associate with the returned region object. You use this identifier to differentiate regions within your application. This value must not be nil.
 */
- (instancetype)initForiBeaconWithUUID:(NSUUID *)uuid
                                 major:(CLBeaconMajorValue)major
                                 minor:(CLBeaconMinorValue)minor
                            identifier:(NSString *)identifier;


#pragma mark - Initialize the manager with an Estimote beacon region to watch for

/**
 Initialize the manager to watch for an Estimote Beacon with any Major or Minor value
 */
- (instancetype)initForEstimote;

/**
 Initialize the manager to watch for an Estimote Beacon with a specific Major value and any Minor value

 @param major The major value that you use to identify one or more beacons.
 */
- (instancetype)initForEstimoteWithMajor:(CLBeaconMajorValue)major;

/**
 Initialize the manager to watch for an Estimote Beacon with a specific Major value and Minor value

 @param major The major value that you use to identify one or more beacons.
 @param minor The minor value that you use to identify one or more beacons.
 */
- (instancetype)initForEstimoteWithMajor:(CLBeaconMajorValue)major
                                   minor:(CLBeaconMinorValue)minor;


#pragma mark - Stop monitoring for region

/**
 Tell BeaconManager to stop monitoring for a Beacon (if currently monitoring).
 */
- (void)stopMonitoringForBeacon;


#pragma mark - Manage CLLocatonManagerDelegate delegates

/**
 Adds an object to the delegate list. It must not be nil, and must implement either CLLocationManagerDelegate or BeaconManagerDelegate. Any non-conforming objects will be ignored.

 @param delegate A non-nil CLLocationManagerDelegate or BeaconManagerDelegate object.
 */
- (void)addDelegate:(id)delegate;

/**
 Removes an object from the delegate list.

 @param delegate A non-nil CLLocationManagerDelegate or BeaconManagerDelegate object.
 */
- (void)removeDelegate:(id)delegate;

/**
 Clear the current delegates.
 */
- (void)clearAllDelegates;


#pragma mark - Use the manager to advertise this device as an iBeacon

/**
 Start/stop advertising the app as an iBeacon. If the beacon was already advertising, it will be stopped first.

 @param uuidString The unique identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool.
 @param major The major value that you use to identify one or more beacons.
 @param minor The minor value that you use to identify one or more beacons.
 @param identifier A unique identifier to associate with the returned region object. You use this identifier to differentiate regions within your application. This value must not be nil.
 @param measuredPower the RSSI of the device observed from one meter in its intended environment. If left nil, a default power of -59 is used.
 */
- (void)startAdvertisingUUID:(NSString *)uuidString
                       major:(CLBeaconMajorValue)majorValue
                       minor:(CLBeaconMinorValue)minorValue
                  identifier:(NSString *)identifier
               measuredPower:(NSNumber *)measuredPower;

/**
 Start advertising the app as an Estimote beacon. If the beacon was already advertising, it will be stopped first.

 This call will trigger a beaconManagerDidStartAdvertisingWithError: method on any BeaconManagerDelegates.

 @param major The major value that you use to identify one or more beacons.
 @param minor The minor value that you use to identify one or more beacons.
 @param measuredPower the RSSI of the device observed from one meter in its intended environment. If left nil, a default power of -59 is used.
 */
- (void)startAdvertisingEstimoteMajorValue:(CLBeaconMajorValue)majorValue
                                minorValue:(CLBeaconMinorValue)minorValue
                             measuredPower:(NSNumber *)measuredPower;

/**
 Stop advertising the device as an iBeacon (or Estimote beacon if applicable).

 This call will trigger a beaconManagerDidStopAdvertising method on any BeaconManagerDelegates.
 */
- (void)stopAdvertising;

@end
