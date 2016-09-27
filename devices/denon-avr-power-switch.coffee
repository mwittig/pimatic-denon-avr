module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing the power switch of the Denon AVR
  class DenonAvrPowerSwitch extends env.devices.PowerSwitch

    # Create a new DenonAvrPowerSwitch device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @interval = @_base.normalize @config.interval, 10
      @debug = @plugin.debug || false
      @plugin.protocolHandler.on 'response', @_onResponseHandler()
      @_state = false
      super()
      process.nextTick () =>
        @_requestUpdate()

    destroy: () ->
      @_base.cancelUpdate()
      super()

    _requestUpdate: () ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      @plugin.protocolHandler.sendRequest 'PW', '?'
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000

    _onResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults
        if response.command is 'PW'
          @_setState if response.param is 'ON' then true else false

    changeStateTo: (newState) ->
      return new Promise (resolve) =>
        @plugin.protocolHandler.sendRequest('PW', if newState then 'ON' else 'STANDBY').then =>
          @_setState newState
          @_requestUpdate()
          resolve()

    getState: () ->
      return Promise.resolve @_state
