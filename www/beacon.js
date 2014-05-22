var exec = require('cordova/exec');
var Beacon;

function BeaconPlugin() {};

// Add callback ability?
BeaconPlugin.prototype.startBeacon = function(successCallback, errorCallback, uuid, identifier, major, minor) {
  exec(successCallback, errorCallback, 'WebBeacon', 'start', [uuid, identifier, major, minor]);
};

BeaconPlugin.prototype.stopBeacon = function(successCallback, errorCallback, identifier) {
  exec(successCallback, errorCallback, 'WebBeacon', 'stop', [identifier]);
};

Beacon = new BeaconPlugin();

module.exports = Beacon;