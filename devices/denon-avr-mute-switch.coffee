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
      @interval = @_base.normalize @config.interval, 10
      @debug = @plugin.debug || false
      @plugin.on 'response', @_onResponseHandler()
      super()
      @_state = false;
      process.nextTick () =>
        @_requestUpdate()

    destroy: () ->
      @_base.cancelUpdate()

    _requestUpdate: () ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      @plugin.connect().then () =>
        @plugin.sendRequest @zoneCmd, '?'
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000

    _onResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults

        switch response.command
          when @zoneCmd then (
            @_setState if response.param is 'ON' then true else false
          )
          when 'PW' then (
            @_requestUpdate()
          )

    changeStateTo: (newState) ->
      return new Promise (resolve) =>
        @plugin.connect().then =>
          @plugin.sendRequest @zoneCmd, if newState then 'ON' else 'OFF'
          @_setState newState
          @_requestUpdate()
          resolve()

    getState: () ->
      return Promise.resolve @_state
