base = require('../base')
HasParent = base.HasParent
safebind = base.safebind
build_views = base.build_views

ActiveToolManager = require('../tools/activetoolmanager').ActiveToolManager

ContinuumView = require('./continuum_view').ContinuumView

ViewState = require('./view_state').ViewState


class PlotView extends ContinuumView

  view_options: () ->
    _.extend({plot_model: @model, plot_view: @}, @options)

  build_renderers: () ->
    build_views(@renderers, @mget_obj('renderers'), @view_options())

  build_axes: () ->
    build_views(@axes, @mget_obj('axes'), @view_options())

  build_tools: () ->
    build_views(@tools, @mget_obj('tools'), @view_options())

  build_overlays: () ->
    #add ids of renderer views into the overlay spec
    build_views(@overlays, @mget_obj('overlays'), @view_options())

  bind_overlays: () ->
    for overlayspec in @mget('overlays')
      @overlays[overlayspec.id].bind_events(this)

  bind_tools: () ->
    for toolspec in @mget('tools')
      @tools[toolspec.id].bind_events(this)

  events:
    "mousemove .canvas_wrapper": "_mousemove"
    "mousedown .canvas_wrapper": "_mousedown"

  _mousedown: (e) ->
    for f in @mousedownCallbacks
      f(e, e.layerX, e.layerY)

  _mousemove: (e) ->
    for f in @moveCallbacks
      f(e, e.layerX, e.layerY)


  initialize: (options) ->
    @throttled = _.throttle(@render_deferred_components, 50)

    super(_.defaults(options, @default_options))

    canvas_height = options.canvas_height ? @mget('canvas_height')
    canvas_width = options.canvas_width  ? @mget('canvas_width')

    offset = if options.offset then options.offset else @mget('offset')

    @view_state = new ViewState(
      canvas_width: canvas_width
      canvas_height: canvas_height
      x_offset: x_offset
      y_offset: y_offset
      inner_width: width
      inner_height: height
      border_top: border_top
      border_bottom: border_bottom
      border_left: border_left
      border_right: border_right
    )

    @renderers = {}
    @axes = {}
    @tools = {}
    @overlays = {}
    @eventSink = _.extend({}, Backbone.Events)
    atm = new ActiveToolManager(@eventSink)
    @moveCallbacks = []
    @mousedownCallbacks = []
    @keydownCallbacks = []
    @render_init()
    @render()
    @build_subviews()
    @throttled()
    return this

  map_to_screen : (x, y, units) ->
    if units == 'screen'
      sx = x[..]
      sy = y[..]
    else
      [sx, sy] = @mapper.v_map_to_target(x, y)

    sx = @view_state.v_sx_to_device(sx)
    sy = @view_state.v_sy_to_device(sy)

    return [sx, sy]

  map_from_screen : (sx, sy, units) ->
    sx = @view_state.v_device_sx(sx[..])
    sy = @view_state.v_device_sx(sy[..])

    if units == 'screen'
      x = sx
      y = sy
    else
      [x, y] = @mapper.v_map_from_target(sx, sy)  # TODO: in-place?

    return [x, y]

  render_init: () ->
    #FIXME template
    @$el.append($("""
      <div class='button_bar'/>
      <div class='bokeh_canvas_wrapper'>
        <canvas class='bokeh_canvas'></canvas>
      </div>
      """))
    @canvas = @$el.find('canvas.bokeh_canvas')
    @canvas_wrapper = @$el.find('.bokeh_canvas_wrapper')

  build_subviews: ()->
    @build_renderers()
    @build_axes()
    @build_tools()
    @build_overlays()
    @bind_tools()
    @bind_overlays()

  bind_bokeh_events: () ->
    safebind(this, @view_state, 'change', @render)
    safebind(this, @model, 'change:renderers', @build_renderers)
    safebind(this, @model, 'change:axes', @build_axes)
    safebind(this, @model, 'change:tools', @build_tools)
    safebind(this, @model, 'change', @render)
    safebind(this, @model, 'destroy', () => @remove())

  # FIXME document throughly when render is called vs render_deferred
  # should we have a "render_init" "render" and a
  # "render_canvas" function add_dom is called at instatiation.
  # "render" is called for plot resizing.  render_canvas is called
  # when changes to the canvas are desired.  A ScatterRendererView
  # would only have a "render_canvas function

  render: () ->
    super()

    oh = @view_state.get('outer_height')
    ow = @view_state.get('outer_width')

    @canvas.attr('style', 'width:#{ow}px; height:#{oh}px')
    @canvas_wrapper.attr('style', 'width:#{ow}px; height:#{oh}px')

    @ctx = @canvas[0].getContext('2d')

    @render_end()

  render_deferred_components: (force) ->
    @ctx.clearRect(0,0,  @view_state.get('width'), @view_state.get('height'))
    all_views = _.flatten(_.map([@renderers, @overlays, @tools], _.values))
    for v in all_views
      v.render(@)


class Plot extends HasParent
  type: 'Plot'
  default_view: PlotView
  parent_properties: [
    'background_fill',
    'border_fill',
    'outer_width',
    'outer_height',
    'border',
    'border_top',
    'border_bottom'
    'border_left'
    'border_right'
  ]
Plot::defaults = _.clone(Plot::defaults)
_.extend(Plot::defaults , {
  'data_sources': {},
  'renderers': [],
  'axes': [],
  'legends': [],
  'tools': [],
  'overlays': [],
  'title': 'Plot'
})
Plot::display_defaults = _.clone(Plot::display_defaults)
_.extend(Plot::display_defaults
  ,
    background_fill: "#eee",
    border_fill: "#eee",
    border: 30
)

class Plots extends Backbone.Collection
   model: Plot


exports.Plot = Plot
exports.PlotView = PlotView
exports.plots = new Plots
