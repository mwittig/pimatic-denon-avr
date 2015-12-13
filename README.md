# pimatic-denon-avr

Pimatic plugin to monitor &amp; control a Denon AV receiver over a network connection

## Status of Implementation

The current implementation is pretty basic. Additional features can be added easily 
and I am happy to do this on demand. Apart from this, I am planning to add an 
auto-discovery feature for the upcoming pimatic v0.9.

## Plugin Configuration

    {
          "plugin": "denon-avr",
          "host": "avr.fritz.box",
    }
    
## Device Configuration

The following devices can be used.

### DenonAvrPresenceSensor

The Presence Sensor presents the power status of the receiver and provides information about 
the master volume and selected input source.

    {
          "id": "avr-1",
          "name": "Denon AVR Status",
          "class": "DenonAvrPresenceSensor"
    }
    
The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds at which the power state of the AVR will be read |
| volumeDecibel     | false    | Boolean | If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed |
    
### DenonAvrPowerSwitch

The Power Switch can be used to switch the AVR on or off (standby) mode. Depending on your
AVR configuration you may not be able to switch it on. See the AVR manual for details.
 
    {
          "id": "avr-2",
          "name": "Denon AVR Power",
          "class": "DenonAvrPowerSwitch"
    }
    
The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds at which the power state of the AVR will be read |

    
### DenonAvrMuteSwitch

The Mute Switch can be used to mute or un-mute the master volume.
    
    {
          "id": "avr-3",
          "name": "Denon AVR Mute",
          "class": "DenonAvrMuteSwitch"
    }
    
The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds at which the power state of the AVR will be read |

    
### DenonAvrMasterVolume

The Master Volume can be used to change the absolute master volume. This device can only 
be used with AVRs which support absolute volume control on a scale from 0-98. As some 
AVRs already stop at lower maximum volume the `maxAbsoluteVolume` property is provided
(see properties table below).

    {
          "id": "avr-4",
          "name": "Denon AVR Master Volume",
          "class": "DenonAvrMasterVolume"
    }
    
The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds at which the power state of the AVR will be read |
| volumeDecibel     | false    | Boolean | If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed |
| volumeLimit       | 0        | Number  | If greater than 0, enforce a volume limiter for the maximum volume level |
| maxAbsoluteVolume | 99       | Number  | Maximum absolute volume which can be set. Some receivers already stop at a lower value than 99 |