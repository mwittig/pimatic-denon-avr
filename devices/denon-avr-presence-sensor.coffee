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
      @interval = config.interval
      @volumeDecibel = config.volumeDecibel
      @debug = @plugin.debug || false
      @plugin.on 'response', @_onResponseHandler()
      @attributes = _.cloneDeep(@attributes)
      @attributes.volume = {
        description: "Volume"
        type: "number"
        acronym: 'VOL'
      }
      @attributes.volume.unit = 'dB' if @volumeDecibel
      @attributes.input = {
        description: "Input Source"
        type: "string"
        acronym: 'INPUT'
      }
      @_presence = false
      @_volume = 0
      @_input = ""
      super()
      process.nextTick () =>
        @_requestUpdate()

    _setAttribute: (attributeName, value) ->
      if @['_' + attributeName] isnt value
        @['_' + attributeName] = value
        @emit attributeName, value

    _scheduleUpdate: () ->
      if @_timeoutObject?
        clearTimeout @_timeoutObject

      if @interval > 0
        env.logger.debug "Next Request in #{@interval * 1000} ms"  if @debug
        @_timeoutObject = setTimeout( =>
          @_timeoutObject = null
          @_requestUpdate()
        , @interval * 1000
        )

    _requestUpdate: () ->
      env.logger.debug "Requesting update" if @debug
      @plugin.connect().then () =>
        @plugin.sendRequest 'PW', '?'
        @plugin.sendRequest 'SI', '?'
        @plugin.sendRequest 'MV', '?'
      .catch (error) =>
        env.logger.debug "Error:", error
      .finally () =>
        @_scheduleUpdate()

    _onResponseHandler: () ->
      return (response) =>
        env.logger.debug "Response", response if @debug
        switch response.command
          when 'PW'
            @_setPresence if response.param is 'ON' then true else false
          when 'SI'
            @_setAttribute 'input', response.param
          when 'MV'
            if @volumeDecibel
              @_setAttribute 'volume', @_volumeToDecibel response.param
            else
              @_setAttribute 'volume', @_volumeToNumber response.param

    _volumeToDecibel: (volume, zeroDB=80) ->
      return @_volumeToNumber(volume) - zeroDB

    _volumeToNumber: (volume) ->
      decimal = if volume.length is 3 then 0.5 else 0
      return decimal + parseInt volume.substring(0, 2)

    getPresence: () ->
      return new Promise.resolve @_presence

    getVolume: () ->
      return new Promise.resolve @_volume

    getInput: () ->
      return new Promise.resolve @_input
