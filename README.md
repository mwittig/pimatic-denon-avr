# pimatic-denon-avr

Pimatic plugin to monitor &amp; control a Denon AV Receiver over a network connection.

![Icon](https://raw.githubusercontent.com/mwittig/pimatic-denon-avr/master/assets/images/logo.png) 

## Status of Implementation

The current implementation is pretty basic, but robust. Additional features can be added easily
and I am happy to do this on demand. Apart from this, I am planning to add an
auto-discovery feature for the upcoming pimatic v0.9.

## Plugin Configuration

    {
          "plugin": "denon-avr",
          "host": "avr.fritz.box",
    }

The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| host              | -        | String  | Hostname or IP address of the AVR |
| port              | 23       | Number  | AVR control port |
| debug             | false    | Boolean | Debug mode. Writes debug messages to the pimatic log, if set to true. |


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

### DenonAvrPowerSwitch

The Power Switch can be used to switch the AVR on or off (standby) mode. Depending on your
AVR configuration you may not be able to switch it on. See the AVR manual for details.

    {
          "id": "avr-2",
          "name": "AVR Power",
          "class": "DenonAvrPowerSwitch"
    }

The device has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |


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
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |


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

## DenonAvrInputSelector

The DenonAvrInputSelector can be used to select the inpit source. Allowed value depend on the AVR model.

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
| interval          | 60       | Number  | The time interval in seconds (minimum 10) at which the power state of the AVR will be read |
| buttons           | see example | Array   | The buttons to display for selection. See device configuration schema for details |

