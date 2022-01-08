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
      @interval = @_base.normalize @config.interval, 2
      @debug = @plugin.debug || false
      
      @protocolHandler = @plugin.getProtocolHandler(@config)
      
      @responseHandler = @_createResponseHandler()
      @protocolHandler.on 'response', @responseHandler
      @_state = false
      super()
      process.nextTick () =>
        @_requestUpdate true

    destroy: () ->
      @_base.cancelUpdate()
      @protocolHandler.removeListener 'response', @responseHandler
      super()

    _requestUpdate: (immediate=false) ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      @protocolHandler.sendRequest 'PW', '?', immediate
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000, true

    _createResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults
        if response.command is 'PW'
          @_setState if response.param is 'ON' then true else false

    changeStateTo: (newState) ->
      return new Promise (resolve, reject) =>
        @protocolHandler.sendRequest('PW', if newState then 'ON' else 'STANDBY').then =>
          @_setState newState
          @_requestUpdate()
          resolve()
        .catch (err) =>
          @_base.rejectWithErrorString reject, err

    getState: () ->
      return Promise.resolve @_state
