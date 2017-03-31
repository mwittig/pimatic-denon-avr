# HttpAppProtocol class
module.exports = (env) ->

  Promise = env.require 'bluebird'
  rest = require('restler-promise')(Promise)
  http = require 'http'
  parseXmlString = Promise.promisify require('xml2js').parseString
  retry = require('promise-retryer')(Promise)
  commons = require('pimatic-plugin-commons')(env)

  # ###DenonAvrPlugin class
  class HttpAppProtocol extends require('events').EventEmitter
    constructor: (@config) ->
      @scheduledUpdates = {}
      @host = @config.host
      @port = @config.port || 80
      @debug = @config.debug || false
      @opts =
        agent: new http.Agent()
      @base = commons.base @, 'HttpAppProtocol'
      @on "newListener", =>
        @base.debug "Status response event listeners: #{1 + @listenerCount 'response'}"

    pause: (ms=50) ->
      @base.debug "Pausing:", ms, "ms"
      Promise.delay ms

    _mapZoneToUrlPath: (command) ->
      switch command[...2]
        when 'Z2' then return 'formZone2_Zone2'
        when 'Z3' then return 'formZone3_Zone3'
        else return 'formMainZone_MainZone'

    _mapZoneToCommandPrefix: (command) ->
      switch command[...2]
        when 'Z2' then return 'Z2'
        when 'Z3' then return 'Z3'
        else return ''

    _mapZoneToObjectKey: (command) ->
      switch command[...2]
        when 'Z2' then return 'zone2'
        when 'Z3' then return 'zone3'
        else return 'main'

    _triggerResponse: (command, param) ->
      # emulate the regex matcher of telnet transport - should be refactored
      @emit 'response',
        matchedResults: [
          "#{command}#{param}"
          "#{command}",
          "#{param}"
          index: 0
          input: "#{command}#{param}"
        ]
        command: command
        param: param
        message: "#{command}#{param}"

    _requestUpdate: (command, param="") =>
      url = "http://#{@host}:#{@port}/goform/#{@_mapZoneToUrlPath command}XmlStatusLite.xml"
      @base.debug url
      return rest.get url, @opts
      .then (response) =>
        if response.data.length isnt 0
          @base.debug response.data
          parseXmlString response.data
          .then (dom) =>
            prefix = @_mapZoneToCommandPrefix command
            @_triggerResponse "#{prefix}MU", dom.item.Mute[0].value[0].toUpperCase()
            @_triggerResponse "#{prefix}PW", dom.item.Power[0].value[0].toUpperCase()
            volume = parseInt(dom.item.MasterVolume[0].value[0], 10)
            if not isNaN volume
              if dom.item.VolumeDisplay[0].value[0].toUpperCase() is 'ABSOLUTE'
                volume += 80
              @_triggerResponse "#{prefix}MV", volume
            @_triggerResponse "#{prefix}SI", dom.item.InputFuncSelect[0].value[0].toUpperCase()
        else
          throw new Error "Empty result received for status request"
      .catch (err) =>
        @base.error err
      .finally =>
        if @scheduledUpdates[@_mapZoneToObjectKey command]?
          delete @scheduledUpdates[@_mapZoneToObjectKey command]

    _scheduleUpdate: (command, param="", immediate) ->
      timeout=1500
      if not @scheduledUpdates[@_mapZoneToObjectKey command]?
        @base.debug "Scheduling update for zone #{@_mapZoneToObjectKey command}"
        @scheduledUpdates[@_mapZoneToObjectKey command] = true
        timeout=0 if immediate
      else
        @base.debug "Re-scheduling update for zone #{@_mapZoneToObjectKey command}"
        @base.cancelUpdate()
      @base.scheduleUpdate @_requestUpdate, timeout, command, param
      return Promise.resolve()

    sendRequest: (command, param="", immediate=false) ->
      return new Promise (resolve, reject) =>
        if param isnt '?'
          url = "http://#{@host}:#{@port}/goform/formiPhoneAppDirect.xml?#{command}#{param}"
          @base.debug url
          promise = rest.get url, @opts
          .then =>
            @_triggerResponse command, param
        else
          promise = @_scheduleUpdate command, param, immediate

        promise.then =>
          resolve()
        .catch (errorResult) =>
          reject errorResult.error