# Denon AVR plugin
module.exports = (env) ->

  Promise = require 'bluebird'
  retry = require('promise-retryer')(Promise)
  net = require 'net'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  deviceConfigTemplates = [
    {
      "name": "Denon AVR Status",
      "class": "DenonAvrPresenceSensor",
      "volumeDecibel": true,
    }
    {
      "name": "Denon AVR Power",
      "class": "DenonAvrPowerSwitch"
    }
    {
      "name": "Denon AVR Zone Switch",
      "class": "DenonAvrZoneSwitch"
    }
    {
      "name": "Denon AVR Mute",
      "class": "DenonAvrMuteSwitch"
    }
    {
      "name": "Denon AVR Master Volume",
      "class": "DenonAvrMasterVolume",
      "maxAbsoluteVolume": 89.5
    }
    {
      "name": "Denon AVR Zone Volume",
      "class": "DenonAvrZoneVolume",
      "maxAbsoluteVolume": 89.5
    }
    {
      "name": "Denon AVR Input Selector",
      "class": "DenonAvrInputSelector",
    }
  ]
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
  class DenonAvrPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @isConnected = false
      @commandQueue = []
      @host = @config.host
      @port = @config.port || 23
      @debug = @config.debug || false
      @lastFlush = new Promise.resolve()
      @connectRequest = new Promise.resolve()
      @_base = commons.base @, 'Plugin'


      # register devices
      deviceConfigDef = require("./device-config-schema")
      for device in deviceConfigTemplates
        className = device.class
        # convert camel-case classname to kebap-case filename
        filename = className.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
        classType = require('./devices/' + filename)(env)
        @_base.debug "Registering device class #{className}"
        @framework.deviceManager.registerDeviceClass(className, {
          configDef: deviceConfigDef[className],
          createCallback: @_callbackHandler(className, classType)
        })

      # auto-discovery
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-denon-avr', 'Searching for AVR controls'
        for device in deviceConfigTemplates
          matched = @framework.deviceManager.devicesConfig.some (element, iterator) =>
            #console.log element.class is device.class, element.class, device.class
            element.class is device.class

          if not matched
            process.nextTick @_discoveryCallbackHandler('pimatic-denon-avr', device.name, device)
      )

    _discoveryCallbackHandler: (pluginName, deviceName, deviceConfig) ->
      return () =>
        @framework.deviceManager.discoveredDevice pluginName, deviceName, deviceConfig

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
          @socket.setTimeout 0
          @socket.destroy()

    _onDataHandler: () ->
      return (data) =>
        responses = data.toString().trim().split '\r'
        #responses = @_base.unique responses
        @_base.debug('Responses:', responses)

        for response in responses
          for command, regex of commands
            matchedResults = response.match regex 
            if matchedResults?
              @emit 'response',
                matchedResults: matchedResults
                command: matchedResults[1]
                param: matchedResults[2]
                message: matchedResults[0]
              break
        responses.length = 0

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
      return new Promise (resolve, reject) =>
        if not @isConnected
          @socket = new net.Socket allowHalfOpen: false
          @socket.setEncoding 'utf8'
          @socket.setNoDelay true
          @socket.setTimeout 10000
          @socket.removeAllListeners()
          @socket.on 'data', @_onDataHandler()
          @socket.once 'timeout', @_onTimeoutHandler()
          @socket.once 'close', @_onCloseHandler()
          @socket.on 'error', @_onErrorHandler()
          @socket.once 'connect', @_onConnectedSuccessHandler(resolve)
          @socket.once 'error', @_onConnectedErrorHandler(reject)
          @_base.debug "Trying to connect to #{@host}:#{@port}"
          @socket.connect @port, @host
        else
          resolve()


    connect: () ->
      return @connectRequest = settled(@connectRequest).then () =>
        retry.run({
          maxRetries: 20
          delay: 1000
          promise: @_connect.bind @
        }).catch (error) =>
          Promise.reject "Unable to connect to #{@host}:#{@port} (retries: 20): " + error


    _write: (cmd) ->
      new Promise (resolve) =>
        @socket.write cmd, () =>
          if cmd.match(/^PWON/)?
            # enforce 2 seconds delay after power on for next command
            @pause(2000).then () =>
              resolve()
          else
            resolve()


    _flush: () ->
      return @lastFlush = settled(@lastFlush).then () =>
        commandsToSend = _.cloneDeep @commandQueue
        @commandQueue.length = 0
        @_base.debug "Flushing:", commandsToSend
        return series(commandsToSend, (cmd) =>
          @_base.debug "Sending:", [cmd]
          @_write cmd
        ).finally () =>
          commandsToSend.length = 0

    pause: (ms=50) ->
      @_base.debug "Pausing:", ms, "ms"
      Promise.delay ms


    sendRequest: (command, param="") ->
      return new Promise (resolve) =>
        commandString ="#{command}#{param}\r"
        # look for duplicate in commandQueue, remove it if found
        #index = @commandQueue.indexOf commandString
        #@commandQueue.splice index, 1 if index >= 0
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