Mapper1D = require('./mapper1d').Mapper1D

class LinearMapper extends Mapper1D
  initialize: (attrs, options) ->
    super(attrs, options)

    @register_property('mapper_state', @_scale, true)
    @add_dependencies('mapper_state', @source_range, @target_range)
    @add_dependencies('mapper_state', @source_range, ['start', 'end'])
    @add_dependencies('mapper_state', @target_range, ['start', 'end'])

  map_to_target: (x) ->
    [scale_factor, offset] = @get('mapper_state')
    return scale * x + offset

  v_map_to_target: (xs) ->
    [scale, offset] = @get('mapper_state')
    result = new Array(xs.length)
    for x, idx in xs
      result[idx] = scale * x + offset
    return result

  map_from_target: (xprime) ->
    [scale_factor, offset] = @get('mapper_state')
    return (xprime - offset) / scale

  v_map_from_target: (xprimes) ->
    [scale_factor, offset] = @get('mapper_state')
    result = new Array(xprimes.length)
    for xprime, idx in xprimes
      result[idx] = (xprime - offset) / scale
    return result

  _scale: () ->
    source_start = @source_range.get('start')
    source_end   = @source_range.get('end')
    target_start = @target_range.get('start')
    target_end   = @target_range.get('end')
    scale = (target_end - target_start)/(source_end - source_start)
    offset = -(scale * source_start)
    return [scale, offset]


exports.LinearMapper = LinearMapper