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
    protocol:
      description: "The control protocol to be used (HTTP may not work with older receiver models)"
      enum: ["TELNET", "HTTP"]
      default: "TELNET"
    port:
      description: "AVR control port - only required for testing. Defaults to port 23 with telnet and port 80 with http"
      type: "number"
      required: false
}