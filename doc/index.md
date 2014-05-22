# KevinBeacon
This plugin exposes a beacon object that currently has to methods.

## Start a Beacon

```
beacon.startBeacon(successCallback, errorCallback, UUID, Identifier, Major, Minor);
```

### Description


## Stop Beacon

```
beacon.stopBeacon(successCallback, errorCallback, Identifier);
```

### Description


## Coming Soon
- Find Available Beacons
- 

Major and minor values provide a little more granularity on top of the UUID. These values are simply 16 bit unsigned integers that identify each individual iBeacon, even ones with the same UUID.
For instance, if you owned multiple department stores you might have all of your iBeacons emit the same UUID, but each store would have its own major value, and each department within that store would have its own minor value. Your app could then respond to an iBeacon located in the shoe department of your Miami, Florida store.