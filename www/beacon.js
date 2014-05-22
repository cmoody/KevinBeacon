var exec = require('cordova/exec');
var Beacon;

function BeaconPlugin() {};

BeaconPlugin.prototype.startBeacon = function(uuid, identifier, major, minor) {
  exec(function() {}, function() {}, 'WebBeacon', 'start', [uuid, identifier, major, minor]);
};

BeaconPlugin.prototype.stopBeacon = function(identifier) {
  exec(function() {}, function() {}, 'WebBeacon', 'stop', [identifier]);
};

Beacon = new BeaconPlugin();

module.exports = Beacon;