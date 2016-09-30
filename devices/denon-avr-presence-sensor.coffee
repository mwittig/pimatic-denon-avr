module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)


  # Device class representing an the power state of the Denon AVR
  class DenonAvrPresenceSensor extends env.devices.PresenceSensor

    # Create a new DenonAvrPresenceSensor device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @interval = @_base.normalize @config.interval, 10
      @volumeDecibel = @config.volumeDecibel
      @debug = @plugin.debug || false
      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler
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
        @_requestUpdate true

    destroy: () ->
      @_base.cancelUpdate()
      @plugin.protocolHandler.removeListener 'response', @responseHandler
      super()

    _requestUpdate: (immediate=false) ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      Promise.all([
        @plugin.protocolHandler.sendRequest 'PW', '?', immediate
        @plugin.protocolHandler.sendRequest 'SI', '?', immediate
        @plugin.protocolHandler.sendRequest 'MV', '?', immediate
      ])
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000, true

    _createResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults
        switch response.command
          when 'PW' then (
            @_setPresence if response.param is 'ON' then true else false
          )
          when 'SI' then (
            @_base.setAttribute 'input', response.param, true
          )
          when 'MV' then (
            if @volumeDecibel
              @_base.setAttribute 'volume', @_volumeToDecibel response.param
            else
              @_base.setAttribute 'volume', @_volumeToNumber response.param
          )

    _volumeToDecibel: (volume, zeroDB=80) ->
      return @_volumeToNumber(volume) - zeroDB

    _volumeToNumber: (volume) ->
      if _.isString volume
        decimal = if volume.length is 3 then 0.5 else 0
        return decimal + parseInt volume.substring(0, 2)
      else
        return volume

    getPresence: () ->
      return new Promise.resolve @_presence

    getVolume: () ->
      return new Promise.resolve @_volume

    getInput: () ->
      return new Promise.resolve @_input
