# Denon AVR plugin
module.exports = (env) ->

  Promise = env.require 'bluebird'
  commons = require('pimatic-plugin-commons')(env)
  TelnetAppProtocol = require('./telnet-app-protocol')(env)
  HttpAppProtocol = require('./http-app-protocol')(env)
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
      @debug = @config.debug || false
      @base = commons.base @, 'Plugin'
      if @config.protocol is 'HTTP'
        @protocolHandler = new HttpAppProtocol @config
      else
        @protocolHandler = new TelnetAppProtocol @config

      # register devices
      deviceConfigDef = require("./device-config-schema")
      for device in deviceConfigTemplates
        className = device.class
        # convert camel-case classname to kebap-case filename
        filename = className.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
        classType = require('./devices/' + filename)(env)
        @base.debug "Registering device class #{className}"
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

  # ###Finally
  # Create a instance of my plugin
  # and return it to the framework.
  return new DenonAvrPlugin