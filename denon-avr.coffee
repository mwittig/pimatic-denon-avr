# Denon AVR plugin
module.exports = (env) ->

  Promise = require 'bluebird'
  retry = require 'bluebird-retry'
  net = require 'net'
  commons = require('pimatic-plugin-commons')(env)
  devices = [
    'denon-avr-presence-sensor'
    'denon-avr-power-switch'
    'denon-avr-mute-switch'
    'denon-avr-master-volume'
  ]
  commands =
    POWER: /^(PW)([A-Z]+)/
    VOLUME: /^(MV)([0-9]+)/
    MUTE: /^(MU)([A-Z]+)/
    INPUT: /^(SI)(.+)/
  settled = (promise) -> Promise.settle([promise])
  series = (input, mapper) -> Promise.mapSeries(input, mapper)


  # ###DenonAvrPlugin class
  class DenonAvrPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @isConnected = false
      @commandQueue = []
      @host = config.host
      @port = config.port || 23
      @debug = config.debug || false
      @lastRequest = new Promise.resolve()
      @connectRequest = new Promise.resolve()
      @_base = commons.base @, 'Plugin'


      # register devices
      deviceConfigDef = require("./device-config-schema")
      for device in devices
        # convert kebap-case to camel-case notation with first character capitalized
        className = device.replace /(^[a-z])|(\-[a-z])/g, ($1) -> $1.toUpperCase().replace('-','')
        classType = require('./devices/' + device)(env)
        @_base.debug "Registering device class #{className}"
        @framework.deviceManager.registerDeviceClass(className, {
          configDef: deviceConfigDef[className],
          createCallback: @_callbackHandler(className, classType)
        })

    _callbackHandler: (className, classType) ->
      # this closure is required to keep the className and classType context as part of the iteration
      return (config, lastState) =>
        return new classType(config, @, lastState)

    _onCloseHandler: () ->
      return () =>
        @_base.debug "Connection closed"

    _onTimeoutHandler: () ->
      return () =>
        if @isConnected
          @_base.debug "Connection idle, closing"
          @isConnected = false
          @socket.setTimeout 0
          @socket.destroy()
        
    _onErrorHandler: () ->
      return (error) =>
        if @isConnected
          @_base.error "Connection Error:", error
          @isConnected = false
          @socket.destroy()

    _onDataHandler: () ->
      return (data) =>
        responses = data.toString().trim().split '\r'
        responses = @_base.unique responses if responses.length > 10

        for response in responses
          for command, regex of commands
            if matchedResults = response.match(regex)
              found =
                matchedResults: matchedResults
                command: matchedResults[1]
                param: matchedResults[2]
                message: matchedResults[0]

              @emit 'response', found
              break

    _onConnectedSuccessHandler: (resolve) ->
      return () =>
        @isConnected = true
        @_base.debug "Connected"
        @socket.removeAllListeners 'error'
        @socket.on 'error', @_onErrorHandler()
        @_flush().then =>
          resolve()

    _onConnectedErrorHandler: (reject) ->
      return (error) =>
        @isConnected = false
        env.logger.debug "Connection failed:", error if @debug
        @socket.removeAllListeners 'connect'
        @socket.destroy()
        reject(error)

    _connect: () ->
      return @connectRequest = settled(@connectRequest).then () =>
        return new Promise (resolve, reject) =>
          if not @isConnected
            @socket = new net.Socket allowHalfOpen: false
            @socket.setEncoding 'utf8'
            @socket.setNoDelay true
            @socket.setTimeout 10000
            @socket.on 'data', @_onDataHandler()
            @socket.on 'timeout', @_onTimeoutHandler()
            @socket.on 'close', @_onCloseHandler()
            @socket.on 'error', @_onErrorHandler()
            @socket.once 'connect', @_onConnectedSuccessHandler(resolve)
            @socket.once 'error', @_onConnectedErrorHandler(reject)
            @_base.debug "Trying to connect to #{@host}:#{@port}"
            @socket.connect @port, @host
          else
            resolve()


    connect: () ->
      return retry(@_connect.bind @, {max_tries: 10, interval: 2000})

    _write: () ->
      return @lastRequest = settled(@lastRequest).then( =>
        @socket.write cmd, () =>
          Promise.delay 500
            .then( =>
              return Promise.resolve
            )
      )
      
    _flush: () ->
      return series(@commandQueue, (cmd) =>
        @socket.write cmd, () =>
          @pause()
      ).finally () =>
        @commandQueue.length = 0

    pause: () ->
      return Promise.delay 1000

    sendRequest: (command, param="") ->
      return new Promise (resolve) =>
        commandString ="#{command}#{param}\r"
        # look for duplicate in commandQueue, remove it if found
        index = @commandQueue.indexOf commandString
        @commandQueue.splice index, 1 if index >= 0
        @commandQueue.push commandString
        process.nextTick () =>
          if @isConnected
            @_flush().then =>
              resolve()
          else
            resolve()

  # ###Finally
  # Create a instance of my plugin
  # and return it to the framework.
  return new DenonAvrPlugin