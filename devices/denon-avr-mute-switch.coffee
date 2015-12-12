module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'

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
      process.nextTick () =>
        @_requestUpdate()

    _scheduleUpdate: () ->
      if @_timeoutObject?
        clearTimeout @_timeoutObject

      if @interval > 0
        @_timeoutObject = setTimeout( =>
          @_timeoutObject = null
          @_requestUpdate()
        , @interval * 1000
        )

    _requestUpdate: () ->
      @plugin.connect().then =>
        @plugin.sendRequest 'MU', '?'
      .finally =>
        @_scheduleUpdate()

    _onResponseHandler: () ->
      return (response) =>
        env.logger.debug "Response", response if @debug
        switch response.command
          when 'MU'
            @_setState if response.param is 'ON' then true else false
          when 'PW'
            @_requestUpdate()

    changeStateTo: (newState) ->
      return new Promise( (resolve) =>
        @plugin.connect().then =>
          @plugin.sendRequest 'MU', if newState then 'ON' else 'OFF'
          @_requestUpdate()
          resolve()
      )

    getState: () ->
      return Promise.resolve @_state
