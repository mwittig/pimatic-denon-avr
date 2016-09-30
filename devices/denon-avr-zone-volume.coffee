module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing an the power state of the Denon AVR
  class DenonAvrZoneVolume extends env.devices.DimmerActuator

    # Create a new DenonAvrZoneVolume device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @zoneCmd = 'MV'
      switch @config.zone
        when 'ZONE2' then (
          @zoneCmd = 'Z2'
        )
        when 'ZONE3' then (
          @zoneCmd = 'Z3'
        )
      @interval = @_base.normalize @config.interval, 10
      @volumeDecibel = @config.volumeDecibel
      @volumeLimit = @_base.normalize @config.volumeLimit, 0, 99
      @maxAbsoluteVolume = @_base.normalize @config.maxAbsoluteVolume, 0, 99
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
      @_dimlevel = 0
      @_state = false
      @_volume = 0
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
      @plugin.protocolHandler.sendRequest @zoneCmd, '?', immediate
      .catch (error) =>
        @_base.error "Error:", error
      .finally () =>
        @_base.scheduleUpdate @_requestUpdate, @interval * 1000, true

    _createResponseHandler: () ->
      return (response) =>
        @_base.debug "Response", response.matchedResults
        if response.command is @zoneCmd and not isNaN response.param
          @_setDimlevel @_volumeParamToLevel response.param
          @_setVolume response.param
        else if response.command is 'MVMAX'
          @maxAbsoluteVolume = Math.min @maxAbsoluteVolume, 0 + response.param

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
      num = Math.round @maxAbsoluteVolume * level / 100
      return if num < 10 then "0" + num else num + ""

    _volumeParamToLevel: (param) ->
      num = @_volumeToNumber param
      return Math.min 100, Math.round(num * 100 / @maxAbsoluteVolume)

    changeDimlevelTo: (newLevel) ->
      return new Promise (resolve) =>
        if @volumeLimit > 0 and newLevel > @volumeLimit
          newLevel = @volumeLimit

        @plugin.protocolHandler.sendRequest(@zoneCmd, @_levelToVolumeParam (newLevel)).then =>
          @_setDimlevel newLevel
          @_requestUpdate()
          resolve()

    getVolume: () ->
      return new Promise.resolve @_volume