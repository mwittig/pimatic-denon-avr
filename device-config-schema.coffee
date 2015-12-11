module.exports = {
  title: "pimatic-denon-avr device config schemas"
  DenonAvrPresenceSensor: {
    title: "Denon AVR Power Switch"
    description: "Denon AVR Power Switch"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      interval:
        description: "The time interval in seconds at which the power state of the AVR will be read"
        type: "number"
        default: 10
  },
  DenonAvrPowerSwitch: {
    title: "Denon AVR Power Switch"
    description: "Denon AVR Power Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      interval:
        description: "The time interval in seconds at which the power state of the AVR will be read"
        type: "number"
        default: 10
  },
  DenonAvrMuteSwitch: {
    title: "Denon AVR Mute Switch"
    description: "Denon AVR Mute Switch"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties:
      interval:
        description: "The time interval in seconds at which the mutr state of the AVR will be read"
        type: "number"
        default: 10
  }
}