# #pimatic-denon-avr plugin config options
module.exports = {
  title: "pimatic-denon-avr plugin config options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
    host:
      description: "Hostname or IP address of the AVR"
      type: "string"
    port:
      description: "AVR control port"
      type: "number"
      default: 23
}