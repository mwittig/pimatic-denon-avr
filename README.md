# pimatic-denon-avr

[![Npm Version](https://badge.fury.io/js/pimatic-denon-avr.svg)](http://badge.fury.io/js/pimatic-denon-avr)
[![Build Status](https://travis-ci.org/mwittig/pimatic-denon-avr.svg?branch=master)](https://travis-ci.org/mwittig/pimatic-denon-avr)
[![Dependency Status](https://david-dm.org/mwittig/pimatic-denon-avr.svg)](https://david-dm.org/mwittig/pimatic-denon-avr)

Pimatic plugin to monitor &amp; control a Denon AV Receiver over a network connection.

![Icon](https://raw.githubusercontent.com/mwittig/pimatic-denon-avr/master/assets/images/logo.png) 

## Status of Implementation

Since the first release the following features have been implemented:
* support for power switching, mute, volume control, input selection, and status display
* support for zone control (up to three zones depending on receiver model)
* auto-discovery for pimatic 0.9
* HTTP transport as an alternative to using telnet for recent AVR models
* action to select input source, devices for power switching, volume mute, volume control are "switch" or "dimmer" 
  devices types and support the respective action operations 

Additional features can be added easily and I am happy to do this on demand. 

## Notable Changes

Since version v0.9.1 changing the master volume automatically switched on the AVR. Unfortunately, it turned
 out that this causes an disruption of video processing with some receivers. Therefore, as of version v0.9.4 changing
  the master volume will no longer switch the AVR.

## Contributions

Contributions to the project are  welcome. You can simply fork the project and create a pull request with 
your contribution to start with. If you like this plugin, please consider &#x2605; starring 
[the project on github](https://github.com/mwittig/pimatic-denon-avr).

## Plugin Configuration

Note, the control protocol is set to TELNET by default. The telnet control is limited to one control 
application connection at a time, as the AVR only accepts a single transport connection. Use the HTTP 
control protocol instead if you have a '11, '12, '13, or X series AVR or a newer model released since 2014.

    {
          "plugin": "denon-avr",
          "host": "avr.fritz.box",
    }

The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| host              | -        | String  | Hostname or IP address of the AVR           |
| port              | 23 or 80 | Number  | AVR control port - only required for testing |
| protocol          | "TELNET" | Enum    | The protocol to be used, one of "HTTP" or "TELNET" |
| debug             | false    | Boolean | Debug mode. Writes debug messages to the pimatic log, if set to true |


## Device Configuration

The following devices can be used. Each device will query the AVR for the status updates at regular time intervals. The
default is 60 seconds. **Note, the AVR will only accept a single connection to the control port.** Shorter intervals may
keep the connection open forever and may block other applications, e.g. remote control applications for the smart
phone. If another application occupies the control port forever the status cannot be updated and commands will
result in 'timeout' errors.  

You may realize some strange behaviour like switches or sliders flipping back to their previous position. This
is due to the behaviour of the AVR control system. When the AVR is in STANDBY it does not allow changing settings like
volume, mute, input and will reply with its currently status parameters.

If the power on command is sent to the AVR, it will take up to 2 seconds for the AVR control system to transition to
the power on state and to accept changing settings. Thus, subsequent commands will be deferred by 2 seconds. You may
realize this, for example, if you change the volume immediately after switching power on, it will take 2 seconds
for the volume attribute to update. In rare cases, if the power on procedure takes longer, the slider may flip back
to its previous position.


### DenonAvrPresenceSensor

The Presence Sensor presents the power status of the receiver and provides information about
the master volume and selected input source.

    {
          "id": "avr-1",
          "name": "AVR Status",
          "class": "DenonAvrPresenceSensor"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |
| volumeDecibel     | false    | Boolean | If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed |

The following predicates and actions are supported:
* `{device} is present|absent`

### DenonAvrPowerSwitch

The Power Switch can be used to switch the AVR on or off (standby) mode. Depending on your
AVR configuration you may not be able to switch it on again. See the AVR manual for details.

    {
          "id": "avr-2",
          "name": "AVR Power",
          "class": "DenonAvrPowerSwitch"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |

The following predicates and actions are supported:
* `{device} is turned on|off`
* `switch {device} on|off`
* `toggle {device}`

### DenonAvrZoneSwitch

The Zone Switch can be used to switch a zone of the AVR on or off if multiple zones are supported and setup for the receiver. 
See the AVR manual for details.

    {
          "id": "avr-2",
          "name": "AVR Zone 2",
          "class": "DenonAvrZoneSwitch"
          "zone": "ZONE2"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| zone              | "MAIN"   | Enum    | The zone to be switched on and off, one of "MAIN", "ZONE2", or "ZONE3" |
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |

The following predicates and actions are supported:
* `{device} is turned on|off`
* `switch {device} on|off`
* `toggle {device}`

### DenonAvrMuteSwitch

![Screenshot](https://raw.githubusercontent.com/mwittig/pimatic-denon-avr/master/assets/screenshots/avr-mute-switch.png)

The Mute Switch can be used to mute or un-mute the master volume.

    {
          "id": "avr-3",
          "name": "AVR Mute",
          "class": "DenonAvrMuteSwitch"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| zone              | "MAIN"   | Enum    | The zone to be muted, one of "MAIN", "ZONE2", or "ZONE3" |
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |

The following predicates and actions are supported:
* `{device} is turned on|off`
* `switch {device} on|off`
* `toggle {device}`

### DenonAvrMasterVolume

![Screenshot](https://raw.githubusercontent.com/mwittig/pimatic-denon-avr/master/assets/screenshots/avr-master-volume.png)

The Master Volume can be used to change the absolute master volume. This device can only
be used with AVRs which support absolute volume control on a scale from 0-98. As some
AVRs already stop at a lower maximum volume the `maxAbsoluteVolume` property is provided
(see properties table below).

    {
          "id": "avr-4",
          "name": "AVR Master Volume",
          "class": "DenonAvrMasterVolume"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |
| volumeDecibel     | false    | Boolean | If true, the volume is presented in dB, otherwise the absolute level between 00 and 99 is displayed |
| volumeLimit       | 0        | Number  | If greater than 0, enforce a volume limiter for the maximum volume level |
| maxAbsoluteVolume | 99       | Number  | Maximum absolute volume which can be set. Some receivers already stop at a lower value than 99 |

The following predicates and actions are supported:
* `dimlevel of {device} {Comparison Operator} {Value}`, where `{Value}` is the percentage of volume 0-100
* `dim {device} to {Value}`, where `{Value}` is the percentage of volume 0-100

### DenonAvrZoneVolume

The Zone Volume can be used to change the  zone volume. 

    {
          "id": "avr-4",
          "name": "AVR Zone Volume",
          "class": "DenonAvrZoneVolume"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| zone              | "MAIN"   | Enum    | The zone for which volume shall be controlled, one of "MAIN", "ZONE2", or "ZONE3". If set to MAIN it is equivalent to master volume |
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |
| volumeDecibel     | false    | Boolean | If true, the volume is presented in dB, otherwise the absolute level between 00 and 99 is displayed |
| volumeLimit       | 0        | Number  | If greater than 0, enforce a volume limiter for the maximum volume level |
| maxAbsoluteVolume | 99       | Number  | Maximum absolute volume which can be set. Some receivers already stop at a lower value than 99 |

The following predicates and actions are supported:
* `dimlevel of {device} {Comparison Operator} {Value}`, where `{Value}` is the percentage of volume 0-100
* `dim {device} to {Value}`, where `{Value}` is percentage of volume 0-100

## DenonAvrInputSelector

The DenonAvrInputSelector can be used to select the input source. Allowed values for input selection
depend on the AVR model.

    {
          "id": "avr-5",
          "name": "AVR Inout Selector",
          "class": "DenonAvrInputSelector"
          "buttons": [
               {
                 "id": "TUNER"
               }
               {
                 "id": "DVD"
               }
               {
                 "id": "TV"
               }
               {
                 "id": "MPLAY"
               }
          ]
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| zone              | "MAIN"   | Enum    | The zone to select input for, one of "MAIN", "ZONE2", or "ZONE3" |
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |
| buttons           | see example | Array   | The buttons to display for selection. See device configuration schema for details |

The following predicates and actions are supported:
* `input of {device} {Comparison Operator} "{Value}"`, where `{Value}` is a string matching a valid input source
* `avr input {device to "{Value}"`, for example: `avr input denon-avr to "tv"`

## History

See [Release History](https://github.com/mwittig/pimatic-denon-avr/blob/master/HISTORY.md).

## License 

Copyright (c) 2015-2017, Marcus Wittig and contributors. All rights reserved.

[AGPL-3.0](https://github.com/mwittig/pimatic-denon-avr/blob/master/LICENSE)