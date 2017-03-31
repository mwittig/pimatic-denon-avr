module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  # Device class representing the power switch of the Denon AVR
  class DenonAvrInputSelector extends env.devices.ButtonsDevice

    # Create a new DenonAvrInputSelector device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @id = @config.id
      @name = @config.name
      @zoneCmd = 'SI'
      switch @config.zone
        when 'ZONE2' then (
          @zoneCmd = 'Z2'
        )
        when 'ZONE3' then (
          @zoneCmd = 'Z3'
        )
      @interval = @_base.normalize @config.interval, 2
      @debug = @plugin.debug || false
      for b in @config.buttons
        b.text = b.id unless b.text?
      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler
      super(@config)
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
        if response.command is @zoneCmd and
            response.param isnt @_lastPressedButton and response.param isnt 'OFF'
          @_lastPressedButton = response.param
          @emit 'button', response.param

    buttonPressed: (buttonId) ->
      for b in @config.buttons
        if b.id is buttonId
          @_lastPressedButton = b.id
          @emit 'button', b.id
          return @plugin.protocolHandler.sendRequest(@zoneCmd, b.id).then =>
            @_requestUpdate()
          .catch (err) =>
            @_base.rejectWithErrorString Promise.reject, err

      throw new Error("No button with the id #{buttonId} found")