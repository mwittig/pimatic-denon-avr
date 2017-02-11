module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  M = env.matcher

  class DenonAvrInputSelectActionHandler extends env.actions.ActionHandler
    constructor: (@framework, @device, @valueTokens) ->
      @_variableManager = @framework.variableManager
      super()

#    setup: ->
#      @dependOnDevice(@device)
#      super()

    executeAction: (simulate) =>
      console.log "----executeAction----", value
      @_variableManager.evaluateStringExpression(@valueTokens)
      .then (value) =>
        @selectInput value, simulate

    selectInput: (input, simulate) =>
      if simulate
        return Promise.resolve(__("would set input #{input}"))
      else
        @device.buttonPressed input
        return Promise.resolve(__("set input #{input}"))

  class DenonAvrInputSelectActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>
      console.log "-----parseAction----", input
      selectorDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.config.class is 'DenonAvrInputSelector'
      ).value()

      # Try to match the input string with: set ->
      m = M(input, context).match(['avr input '])

      device = null
      match = null
      valueTokens = null

      m.matchDevice selectorDevices, (m, d) ->
        # Already had a match with another device?
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return

        device = d
        m.match(' to ')
        .matchStringWithVars( (next, ts) =>
          valueTokens = ts
          match = next.getFullMatch()
        )

      console.log "-----------------------", match, valueTokens

      if match?
        assert device?
        assert valueTokens?
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new DenonAvrInputSelectActionHandler(@framework, device, valueTokens)
        }
      else
        return null

  return DenonAvrInputSelectActionProvider
