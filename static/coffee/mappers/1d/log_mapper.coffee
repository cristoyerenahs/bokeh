Mapper1D = require('./mapper1d').Mapper1D


class LogMapper extends Mapper1D
  initialize: (attrs, options) ->
    super(attrs, options)

  map_to_target: (x) ->

  v_map_to_target: (xs) ->
    result = new Array(xs.length)
    return result

  map_from_target: (xprime) ->

  v_map_from_target: (xprimes) ->
    result = new Array(xprimes.length)
    return result


exports.LogMapper = LogMapper