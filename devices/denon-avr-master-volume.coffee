module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an the power state of the Denon AVR
  class DenonAvrMasterVolume extends env.devices.DimmerActuator

    # Create a new DenonAvrMasterVolume device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @interval = @_base.normalize @config.interval, 10
      @volumeDecibel = @config.volumeDecibel
      @volumeLimit = @_base.normalize @config.volumeLimit, 0, 99
      @maxAbsoluteVolume = @_base.normalize @config.maxAbsoluteVolume, 0, 99
      @debug = @plugin.debug || false
      @plugin.on 'response', @_onResponseHandler()
      @attributes = _.cloneDeep(@attributes)
      @attributes.volume = {
        description: "Volume"
        type: "number"
        acronym: 'VOL'
      }
      @attributes.volume.unit = 'dB' if @volumeDecibel
      @_dimlevel = 0
      @_state = false
      @_volume = 0
      super()
      process.nextTick () =>
        @_requestUpdate()

    destroy: () ->
      @_base.cancelUpdate()

    _requestUpdate: () ->
      @_base.cancelUpdate()
      @_base.debug "Requesting update"
      @plugin.connect().then () =>
        @plugin.sendRequest 'MV', '?'
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate(@_requestUpdate, @interval * 1000)

    _onResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults
        if response.command is 'MV'
          @_setDimlevel @_volumeParamToLevel response.param
          @_setVolume response.param

    _volumeToDecibel: (volume, zeroDB=80) ->
      return @_volumeToNumber(volume) - zeroDB

    _volumeToNumber: (volume) ->
      if _.isString volume
        decimal = if volume.length is 3 then 0.5 else 0
        return decimal + parseInt volume.substring(0, 2)
      else
        return volume

    _setVolume: (volume) ->
      if @volumeDecibel
        @_base.setAttribute 'volume', @_volumeToDecibel volume
      else
        @_base.setAttribute 'volume', @_volumeToNumber volume

    _levelToVolumeParam: (level) ->
      num = Math.floor @maxAbsoluteVolume * level / 100
      return if num < 10 then "0" + num else num + ""

    _volumeParamToLevel: (param) ->
      num = @_volumeToNumber param
      return Math.floor num * 100 / @maxAbsoluteVolume

    changeDimlevelTo: (newLevel) ->
      return new Promise (resolve) =>
        if @volumeLimit > 0 and newLevel > @volumeLimit
          newLevel = @volumeLimit

        @plugin.connect().then =>
          @plugin.sendRequest 'MV', @_levelToVolumeParam (newLevel)
          @_setDimlevel newLevel
          @_requestUpdate()
          resolve()

    getVolume: () ->
      return new Promise.resolve @_volume