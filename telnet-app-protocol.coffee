# TelnetAppProtocol class
module.exports = (env) ->

  Promise = env.require 'bluebird'
  retry = require('promise-retryer')(Promise)
  net = require 'net'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  commands =
    POWER: /^(PW)([A-Z]+)/
    VOLUME: /^(MV)([0-9]+)/
    MAXVOLUME: /^(MVMAX)[ ]{0,1}([0-9]+)/
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
  class TelnetAppProtocol extends require('events').EventEmitter
    constructor: (@config) ->
      @isConnected = false
      @commandQueue = []
      @host = @config.host
      @port = @config.port || 23
      @debug = @config.debug || false
      @lastFlush = new Promise.resolve()
      @connectRequest = new Promise.resolve()
      @base = commons.base @, 'TelnetAppProtocol'

    _onCloseHandler: () ->
      return () =>
        @base.debug "Connection closed"

    _onTimeoutHandler: () ->
      return () =>
        if @isConnected
          @base.debug "Connection idle, closing"
          @isConnected = false
          @socket.setTimeout 0
          @socket.destroy()

    _onErrorHandler: () ->
      return (error) =>
        if @isConnected
          @base.error "Connection Error:", error
          @isConnected = false
          @socket.setTimeout 0
          @socket.destroy()

    _onDataHandler: () ->
      return (data) =>
        responses = data.toString().trim().split '\r'
        #responses = @base.unique responses
        @base.debug('Responses:', responses)

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
        @base.debug "Connected"
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
          @base.debug "Trying to connect to #{@host}:#{@port}"
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
        @base.debug "Flushing:", commandsToSend
        return series(commandsToSend, (cmd) =>
          @base.debug "Sending:", [cmd]
          @_write cmd
        ).finally () =>
          commandsToSend.length = 0

    pause: (ms=50) ->
      @base.debug "Pausing:", ms, "ms"
      Promise.delay ms


    sendRequest: (command, param="") ->
      return new Promise (resolve, reject) =>
        @connect().then( =>
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
        ).catch (error) =>
          reject error