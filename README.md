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
    
### DenonAvrPowerSwitch

The Power Switch can be used to switch the AVR on or off (standby) mode. Depending on your
AVR configuration you may not be able to switch it on. See the AVR manual for details.
 
    {
      "id": "avr-2",
      "name": "Denon AVR Power",
      "class": "DenonAvrPowerSwitch"
    }
    
### DenonAvrMuteSwitch

The Mute Switch can be used to mute or un-mute the master volume.
    
    {
      "id": "avr-3",
      "name": "Denon AVR Mute",
      "class": "DenonAvrMuteSwitch"
    }