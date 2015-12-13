module.exports = {
  title: "pimatic-denon-avr device config schemas"
  DenonAvrPresenceSensor: {
    title: "Denon AVR Power Switch"
    description: "Denon AVR Power Switch"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
      volumeDecibel:
        description: "If true, the volume is presented in dB, otherwise relative level between 00 and 99 is displayed"
        type: "boolean"
        default: false
  },
  DenonAvrMasterVolume: {
    title: "Denon AVR Master Volume"
    description: "Denon AVR Master Volume"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      interval:
        description: "The time interval in seconds (minimum 10) at which the power state of the AVR will be read"
        type: "number"
        default: 60
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
  },
  DenonAvrMuteSwitch: {
    title: "Denon AVR Mute Switch"
    description: "Denon AVR Mute Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      interval:
        description: "The time interval in seconds (minimum 10) at which the mutr state of the AVR will be read"
        type: "number"
        default: 60
  }
}