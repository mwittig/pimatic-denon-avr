module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'

  # Device class representing an the power state of the Denon AVR
  class DenonAvrPresenceSensor extends env.devices.PresenceSensor

    # Create a new DenonAvrPresenceSensor device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @id = config.id
      @name = config.name
      @interval = config.interval || 60
      @debug = @plugin.debug || false
      @plugin.on 'response', @_onResponseHandler()
      @attributes = _.cloneDeep(@attributes)
      @attributes.volume = {
        description: "Volume"
        type: "number"
        acronym: 'VOL'
      }
      @attributes.input = {
        description: "Input Source"
        type: "string"
        acronym: 'INPUT'
      }
      @_presence = false
      @_volume = 0
      @_input = ""
      super()

      @_requestUpdate()
      @_scheduleUpdate()

    _setAttribute: (attributeName, value) ->
      if @['_' + attributeName] isnt value
        @['_' + attributeName] = value
        @emit attributeName, value

    _scheduleUpdate: () ->
      if @_timeoutObject?
        clearTimeout @_timeoutObject

      if @interval > 0
        # keep updating
        @_timeoutObject = setTimeout( =>
          @_timeoutObject = null
          @_requestUpdate()
        , @interval * 1000
        )

    _requestUpdate: () ->
      @plugin.connect().then =>
        @plugin.sendRequest 'PW', '?'
        @plugin.sendRequest 'SI', '?'
        @plugin.sendRequest 'MV', '?'

    _onResponseHandler: () ->
      return (response) =>
        env.logger.debug "Response", response if @debug
        switch response.command
          when 'PW'
            @_setPresence if response.param is 'ON' then true else false
          when 'SI'
            @_setAttribute 'input', response.param
          when 'MV'
            @_setAttribute 'volume', response.param

    getPresence: () ->
      return new Promise.resolve @_presence
