# Denon AVR plugin
module.exports = (env) ->

  Promise = env.require 'bluebird'
  retry = require 'bluebird-retry'
  net = require 'net'
  devices = [
    'denon-avr-presence-sensor'
    'denon-avr-power-switch'
    'denon-avr-mute-switch'
  ]
  commands =
    POWER: /^(PW)([A-Z]+)/
    VOLUME: /^(MV)([0-9]+)/
    MUTE: /^(MU)([A-Z]+)/
    INPUT: /^(SI)(.+)/


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

      # register devices
      deviceConfigDef = require("./device-config-schema")
      for device in devices
        # convert kebap-case to camel-case notation with first character capitalized
        className = device.replace /(^[a-z])|(\-[a-z])/g, ($1) -> $1.toUpperCase().replace('-','')
        classType = require('./devices/' + device)(env)
        env.logger.debug "Registering device class #{className}" if @debug
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
        env.logger.debug "Connection closed" if @debug

    _onTimeoutHandler: () ->
      return () =>
        env.logger.debug "Connection idle, closing"
        @isConnected = false
        @socket.setTimeout 0
        @socket.destroy()
        
    _onErrorHandler: () ->
      return (error) =>
        env.logger.debug "Connection Error:", error if @debug

    _onDataHandler: () ->
      return (data) =>
        responses = data.toString().trim().split '\r'
        found = null

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
        env.logger.debug "Connected" if @debug
        @socket.removeAllListeners 'error'
        @socket.on 'error', @_onErrorHandler()
        @_flush().then =>
          resolve()

    _onConnectedErrorHandler: (reject) ->
      return (error) =>
        @isConnected = false
        env.logger.debug "Connection failed:", error if @debug
        @socket.removeAllListeners 'connect'
        reject(error)

    _connect: () ->
      return @connectRequest = Promise.settle([@connectRequest]).then () =>
        return new Promise (resolve, reject) =>
          if not @isConnected
            @socket = new net.Socket allowHalfOpen: false
            @socket.setEncoding 'utf8'
            @socket.setNoDelay true
            @socket.setTimeout 5000
            @socket.on 'data', @_onDataHandler()
            @socket.on 'timeout', @_onTimeoutHandler()
            @socket.on 'close', @_onCloseHandler()
            @socket.on 'error', @_onErrorHandler()
            @socket.once 'connect', @_onConnectedSuccessHandler(resolve)
            @socket.once 'error', @_onConnectedErrorHandler(reject)
            env.logger.debug "Trying to connect to #{@host}:#{@port}" if @debug
            @socket.connect @port, @host
          else
            resolve()


    connect: () ->
      return  retry(@_connect.bind @,
        {max_tries: 10, max_interval: 30000, interval: 1000, backoff: 2})

    close: () ->
      return @lastRequest = Promise.settle([@lastRequest]).then( =>
        return new Promise (resolve) =>
          if @isConnected
            @isConnected = false
            @socket.end()
          resolve()
      )

    _write: () ->
      return @lastRequest = Promise.settle([@lastRequest]).then( =>
        @socket.write cmd, () =>
          Promise.delay 500
            .then( =>
              return Promise.resolve
            )
      )
      
    _flush: () ->
      writers = []
      while cmd = @commandQueue.shift()
        writers.push @socket.write cmd

      result = Promise.all(writers).then( =>
        writers.length = 0
      )
      return result

    pause: () ->
      return Promise.delay 500

    sendRequest: (command, param="") ->
      return new Promise (resolve) =>
        @commandQueue.push "#{command}#{param}\r"
        if @isConnected
          @_flush().then =>
            resolve()

  # ###Finally
  # Create a instance of my plugin
  # and return it to the framework.
  return new DenonAvrPlugin