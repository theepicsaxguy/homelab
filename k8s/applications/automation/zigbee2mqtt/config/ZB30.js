const fz = require('zigbee-herdsman-converters/converters/fromZigbee');
const tz = require('zigbee-herdsman-converters/converters/toZigbee');
const exposes = require('zigbee-herdsman-converters/lib/exposes');
const reporting = require('zigbee-herdsman-converters/lib/reporting');
const extend = require('zigbee-herdsman-converters/lib/extend');
const e = exposes.presets;
const ea = exposes.access;

const definition = {
    zigbeeModel: ['MotionSensor-ZB3.0'], // The model ID from: Device with modelID 'lumi.sens' is not supported.
    model: 'S902M-ZG', // Vendor model number, look on the device for a model number
    vendor: 'HZC',
    description: 'Electric motion sensor',
    fromZigbee: [fz.ias_occupancy_alarm_1, fz.battery, fz.illuminance],
    toZigbee: [], // Should be empty, unless device can be controlled (e.g. lights, switches).
    exposes: [e.occupancy(), e.battery_low(), e.battery(), e.illuminance(), e.tamper()], // Defines what this device exposes, used for e.g. Home Assistant discovery and in the frontend
};

module.exports = [definition];
definition.exposes.push(e.linkquality());
