//
//  MMWebBeacon.m
//  WebBeacon
//
//  Created by Jeff Gilbert on 2/18/14.
//
//

#import "MMWebBeacon.h"
#import "BeaconManager.h"


@interface MMWebBeacon() <CLLocationManagerDelegate>
@property (nonatomic, strong)   BeaconManager*  beacon;
@end


@implementation MMWebBeacon

- (void)start:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* uuidString = command.arguments[0];
    NSString* identifier = command.arguments[1];
    NSNumber* major = command.arguments[2];
    NSNumber* minor = command.arguments[3];
    
    if ([self isArgumentPresent:uuidString] && [self isArgumentPresent:identifier])
    {
        NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
        BOOL hasMajor = [self isArgumentPresent:major];
        BOOL hasMinor = [self isArgumentPresent:minor];
        
        if (hasMajor && hasMinor)
        {
            self.beacon = [[BeaconManager alloc] initForiBeaconWithUUID:uuid major:[major intValue] minor:[minor intValue] identifier:identifier];
        }
        else if (hasMajor)
        {
            self.beacon = [[BeaconManager alloc] initForiBeaconWithUUID:uuid major:[major intValue] identifier:identifier];
        }
        else
        {
            self.beacon = [[BeaconManager alloc] initForiBeaconWithUUID:uuid identifier:identifier];
        }
        
        [self.beacon addDelegate:self];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"UUID and identifier are required"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (BOOL)isArgumentPresent:(id)argument
{
    return (argument != nil) && (argument != [NSNull null]);
}


- (void)stop:(CDVInvokedUrlCommand*)command
{
    self.beacon = nil;
}


- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSArray* jsonBeacons = [self jsonArrayWithBeacons:beacons];
    NSString* beaconsString = [self stringForJSON:jsonBeacons];
    
    NSString* javascript = [NSString stringWithFormat:@"$(window).trigger('beaconNotification', %@);", beaconsString];
    [self.commandDelegate evalJs:javascript scheduledOnRunLoop:YES];
}


- (NSArray*)jsonArrayWithBeacons:(NSArray*)beacons
{
    NSMutableArray* json = [NSMutableArray arrayWithCapacity:[beacons count]];
    
    for (CLBeacon* beacon in beacons)
    {
        NSDictionary* jsonBeacon = [self jsonDictionaryWithBeacon:beacon];
        [json addObject:jsonBeacon];
    }
    
    return json;
}


- (NSDictionary*)jsonDictionaryWithBeacon:(CLBeacon*)beacon
{
    return @{@"uuid": [beacon.proximityUUID UUIDString],
             @"major": beacon.major,
             @"minor": beacon.minor,
             @"proximity": @(beacon.proximity),
             @"accuracy": @(beacon.accuracy),
             @"rssi": @(beacon.rssi)};
}


- (NSString*)stringForJSON:(id)json
{
    NSData* data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return string;
}

@end
