module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing the power switch of the Denon AVR
  class DenonAvrMuteSwitch extends env.devices.PowerSwitch

    # Create a new DenonAvrMuteSwitch device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @zoneCmd = 'MU'
      switch @config.zone
        when 'ZONE2' then (
          @zoneCmd = 'Z2MU'
        )
        when 'ZONE3' then (
          @zoneCmd = 'Z3MU'
        )
      @lastPowerState=null
      @interval = @_base.normalize @config.interval, 10
      @debug = @plugin.debug || false
      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler
      super()
      @_state = false;
      process.nextTick () =>
        @_requestUpdate true

    destroy: () ->
      @_base.cancelUpdate()
      @plugin.protocolHandler.removeListener 'response', @responseHandler
      super()

    _requestUpdate: (immediate=false) ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      @plugin.protocolHandler.sendRequest @zoneCmd, '?', immediate
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000, true

    _createResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults

        switch response.command
          when @zoneCmd then (
            @_setState if response.param is 'ON' then true else false
          )
          when 'PW' then (
            powerState = response.param is 'ON'
            @_requestUpdate() if powerState isnt @lastPowerState
            @lastPowerState = powerState
          )

    changeStateTo: (newState) ->
      return new Promise (resolve, reject) =>
        @plugin.protocolHandler.sendRequest(@zoneCmd, if newState then 'ON' else 'OFF').then =>
          @_setState newState
          @_requestUpdate()
          resolve()
        .catch (err) =>
          @_base.rejectWithErrorString reject, err

    getState: () ->
      return Promise.resolve @_state
