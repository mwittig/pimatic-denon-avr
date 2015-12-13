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
      @id = config.id
      @name = config.name
      @interval = config.interval
      @debug = @plugin.debug || false
      @plugin.on 'response', @_onResponseHandler()
      super()
      @_state = false;
      @_base = commons.base @, 'DenonAvrMuteSwitch'
      process.nextTick () =>
        @_requestUpdate()

    _requestUpdate: () ->
      @_base.debug "Requesting update"
      @plugin.connect().then () =>
        @plugin.sendRequest 'MU', '?'
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000

    _onResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults

        switch response.command
          when 'MU'
            @_setState if response.param is 'ON' then true else false
          when 'PW'
            @_requestUpdate()

    changeStateTo: (newState) ->
      return new Promise( (resolve) =>
        @plugin.connect().then =>
          @plugin.sendRequest 'MU', if newState then 'ON' else 'OFF'
          @_setState newState
          @_requestUpdate()
          resolve()
      )

    getState: () ->
      return Promise.resolve @_state
