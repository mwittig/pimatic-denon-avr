# HttpAppProtocol class
module.exports = (env) ->

  Promise = env.require 'bluebird'
  rest = require('restler-promise')(Promise)
  parseXmlString = Promise.promisify require('xml2js').parseString
  retry = require('promise-retryer')(Promise)
  commons = require('pimatic-plugin-commons')(env)

  commands =
    POWER: /^(PW)([A-Z]+)/
    VOLUME: /^(MV)([0-9]+)/
    MAINMUTE: /^(MU)([A-Z]+)/
    Z2MUTE: /^(Z2MU)([A-Z]+)/
    Z3MUTE: /^(Z3MU)([A-Z]+)/
    INPUT: /^(SI)(.+)/
    MAIN: /^(ZM)(.+)/
    ZONE2: /^(Z2)(.+)/
    ZONE3: /^(Z3)(.+)/

  settled = (promise) -> promise.reflect()
  series = (input, mapper) -> Promise.mapSeries(input, mapper)


  # ###DenonAvrPlugin class
  class HttpAppProtocol extends require('events').EventEmitter
    constructor: (@config) ->
      @scheduledUpdates = {}
      @host = @config.host
      @port = @config.port || 80
      @debug = @config.debug || false
      @base = commons.base @, 'HttpAppProtocol'

    pause: (ms=50) ->
      @base.debug "Pausing:", ms, "ms"
      Promise.delay ms

    _mapZoneToUrlPath: (command) ->
      switch command[...2]
        when 'Z2' then return 'formZone2_Zone2'
        when 'Z3' then return 'formZone3_Zone3'
        else return 'formMainZone_MainZone'

    _mapZoneToPrefix: (command) ->
      switch command[...2]
        when 'Z2' then return 'Z2'
        when 'Z3' then return 'Z3'
        else return ''

    _mapZoneToKey: (command) ->
      switch command[...2]
        when 'Z2' then return 'zone2'
        when 'Z3' then return 'zone2'
        else return 'main'

    _triggerResponse: (command, param) ->
      @emit 'response',
        matchedResults: [
          "#{command}#{param}"
          "#{command}",
          "#{param}"
          index:0
          input: "#{command}#{param}"
        ]
        command: command
        param: param
        message: "#{command}#{param}"

    _requestUpdate: (command, param="") =>
      @base.debug "http://#{@host}:#{@port}/goform/#{@_mapZoneToUrlPath command}XmlStatusLite.xml"
      return rest.get "http://#{@host}:#{@port}/goform/#{@_mapZoneToUrlPath command}XmlStatusLite.xml"
      .then (response) =>
        if response.data.length isnt 0
          parseXmlString response.data
          .then (dom) =>
            delete @scheduledUpdates[@_mapZoneToKey command] if @scheduledUpdates[@_mapZoneToKey command]?
            prefix = @_mapZoneToPrefix command
            @_triggerResponse "#{prefix}MU", dom.item.Mute[0].value[0].toUpperCase()
            @_triggerResponse "#{prefix}PW", dom.item.Power[0].value[0].toUpperCase()
            volume = parseInt dom.item.MasterVolume[0].value[0], 10
            if dom.item.VolumeDisplay[0].value[0].toUpperCase() is 'ABSOLUTE'
              volume += 80
            @_triggerResponse "#{prefix}MV", volume
            @_triggerResponse "#{prefix}SI", dom.item.InputFuncSelect[0].value[0].toUpperCase()

    _scheduleUpdate: (command, param="") ->
      if not @scheduledUpdates[@_mapZoneToKey command]?
        @base.debug "Scheduling update for zone #{@_mapZoneToKey command}"
        @scheduledUpdates[@_mapZoneToKey command] = true
        @base.scheduleUpdate @_requestUpdate, 1000, command, param
      return Promise.resolve()

    sendRequest: (command, param="") ->
      return new Promise (resolve, reject) =>
        if param isnt '?'
          @base.debug "http://#{@host}:#{@port}/goform/formiPhoneAppDirect.xml?#{command}#{param}"
          promise = rest.get "http://#{@host}:#{@port}/goform/formiPhoneAppDirect.xml?#{command}#{param}"
          .then =>
            @_triggerResponse command, param
        else
          promise = @_scheduleUpdate command, param

        promise.then =>
          resolve()
        .catch (errorResult) =>
          reject errorResult.error