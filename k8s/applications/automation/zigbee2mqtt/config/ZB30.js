const fz      = require('zigbee-herdsman-converters/converters/fromZigbee');
const exposes = require('zigbee-herdsman-converters/lib/exposes');
const e       = exposes.presets;

module.exports = [{
  zigbeeModel : ['MotionSensor-ZB3.0'],
  model       : 'S902M-ZG',
  vendor      : 'HZC',
  description : 'Electric motion sensor',
  fromZigbee  : [fz.ias_occupancy_alarm_1, fz.battery, fz.illuminance],
  toZigbee    : [],
  exposes     : [
    e.occupancy(),
    e.battery_low(),
    e.battery(),
    e.illuminance(),
    e.tamper(),          // <-- done – linkquality is automatic
  ],
}];
