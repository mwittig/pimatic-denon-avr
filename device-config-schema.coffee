module.exports = {
  title: "pimatic-denon-avr device config schemas"
  DenonAvrPresenceSensor: {
    title: "Denon AVR Power Switch"
    description: "Denon AVR Power Switch"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel", "xAttributeOptions"]
    properties:
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
      volumeDecibel:
        description: "If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed"
        type: "boolean"
        default: false
  },
  DenonAvrMasterVolume: {
    title: "Denon AVR Master Volume"
    description: "Denon AVR Master Volume"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel", "xAttributeOptions"]
    properties:
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
      volumeDecibel:
        description: "If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed"
        type: "boolean"
        default: false
      volumeLimit:
        description: "If greater than 0, enforce a volume limiter for the maximum volume level"
        type: "number"
        default: 0
      maxAbsoluteVolume:
        description: "Maximum absolute volume which can be set. Some receivers already stop at a lower value than 99"
        type: "number"
        default: 99
  },
  DenonAvrZoneVolume: {
    title: "Denon AVR Zone Volume"
    description: "Denon AVR Zone Volume"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel", "xAttributeOptions"]
    properties:
      zone:
        description: "The zone for which volume shall be controlled. If set to MAIN it is equivalent to master volume"
        enum: ["MAIN", "ZONE2", "ZONE3"]
        default: "MAIN"
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
      volumeDecibel:
        description: "If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed"
        type: "boolean"
        default: false
      volumeLimit:
        description: "If greater than 0, enforce a volume limiter for the maximum volume level"
        type: "number"
        default: 0
      maxAbsoluteVolume:
        description: "Maximum absolute volume which can be set. Some receivers already stop at a lower value than 99"
        type: "number"
        default: 99
  },
  DenonAvrPowerSwitch: {
    title: "Denon AVR Power Switch"
    description: "Denon AVR Power Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
  },
  DenonAvrZoneSwitch: {
    title: "Denon AVR Zone Switch"
    description: "Denon AVR Zone Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      zone:
        description: "The zone to be controlled"
        enum: ["MAIN", "ZONE2", "ZONE3"]
        default: "MAIN"
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
  },
  DenonAvrMuteSwitch: {
    title: "Denon AVR Mute Switch"
    description: "Denon AVR Mute Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      zone:
        description: "The zone to be controlled"
        enum: ["MAIN", "ZONE2", "ZONE3"]
        default: "MAIN"
      interval:
        description: "The time interval in seconds (minimum 10) at which the mutr state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
  },
  DenonAvrInputSelector: {
    title: "Denon AVR Input Selector"
    description: "Denon AVR Input Selector"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      zone:
        description: "The zone to be controlled"
        enum: ["MAIN", "ZONE2", "ZONE3"]
        default: "MAIN"
      interval:
        description: "The time interval in seconds (minimum 10) at which the mutr state of the AVR will be read"
        type: "number"
        default: 60
        minimum: 10
      buttons:
        description: "The inputs to select from"
        type: "array"
        default: [
          {
            id: "TUNER"
          }
          {
            id: "DVD"
          }
          {
            id: "TV"
          }
          {
            id: "MPLAY"
          }
        ]
        format: "table"
        items:
          type: "object"
          properties:
            id:
              enum: [
                "CD", "TUNER", "DVD", "BD", "TV", "SAT/CBL", "MPLAY", "GAME", "HDRADIO", "NET",
                "PANDORA", "SIRIUSXM", "SPOTIFY", "LASTFM", "FLICKR", "IRADIO", "SERVER", "FAVORITES",
                "AUX1", "AUX2", "AUX3", "AUX4", "AUX5", "AUX6", "AUX7", "BT", "USB", "USB/IPOD",
                "IPD", "IRP", "FVP",
              ]
              description: "The input ids switchable by the AVR"
            text:
              type: "string"
              description: "The button text to be displayed. The id will be displayed if not set"
              required: false
            confirm:
              description: "Ask the user to confirm the input select"
              type: "boolean"
              default: false
  }
}