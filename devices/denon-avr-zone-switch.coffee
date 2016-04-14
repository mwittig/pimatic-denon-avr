module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing the zone switch of the Denon AVR, i.e., a switch to switch a zone on and off
  class DenonAvrZoneSwitch extends env.devices.PowerSwitch

    # Create a new DenonAvrZoneSwitch device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @zoneCmd = 'ZM'
      switch @config.zone
        when 'ZONE2' then (
          @zoneCmd = 'Z2'
        )
        when 'ZONE3' then (
          @zoneCmd = 'Z3'
        )
      @interval = @_base.normalize @config.interval, 10
      @debug = @plugin.debug || false
      @plugin.on 'response', @_onResponseHandler()
      @_state = false
      super()
      process.nextTick () =>
        @_requestUpdate()

    _requestUpdate: () ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      @plugin.connect().then =>
        @plugin.sendRequest @zoneCmd, '?'
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000

    _onResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults
        if response.command is @zoneCmd
          if response.param is 'ON'
            @_setState true
          else if response.param is 'OFF'
            @_setState false

    changeStateTo: (newState) ->
      return new Promise (resolve) =>
        @plugin.connect().then =>
          @plugin.sendRequest @zoneCmd, if newState then 'ON' else 'OFF'
          @_setState newState
          @_requestUpdate()
          resolve()

    getState: () ->
      return Promise.resolve @_state
