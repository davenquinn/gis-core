mapnik = require 'mapnik'
path = require 'path'
fs = require 'fs'
d3 = require 'd3'
{fileExists} = require './util'
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()
mapnik.register_system_fonts()
{bboxPolygon} = require 'turf'

Promise = require 'bluebird'
# load map config
loadCfg = require '../config/map'

boundsFromEnvelope = (bbox)->
  if bbox.geometry?
    bbox = bbox.geometry
  if bbox.coordinates?
    c = bbox.coordinates
    if bbox.type == 'Polygon'
      c = c[0]
    return [c[0][0],c[0][1],c[2][0],c[2][1]]
  return bbox

ECANNOTRENDER = "Can't render – layers could not be loaded."

class StaticMap
  constructor: (@size, bbox, name, extraCfg={})->
    ###
    Can use bounding box or tuple of urx,ury,llx,lly
    ###
    MPATH = process.env.MAPNIK_STYLES
    name ?= "ortho"
    extraCfg.layers ?= process.env.MAPNIK_LAYERS
    cfg = path.join(MPATH,"#{name}.yaml")
    mapData = loadCfg cfg, extraCfg

    @_map = new mapnik.Map @size.width*2, @size.height*2
    @canRender = false
    try
      @_map.fromStringSync mapData.xml
      @canRender = true
    catch err
      console.error err
      # Construct a bare-bones map without layers
      match = /srs="[^"]+"/.exec mapData.xml
      srs = match[0]
      ms ="<Map #{srs} />"
      @_map.fromStringSync ms
    bbox ?= [200,200,-200,-200]
    @setBounds bbox
    @__render = (opts)=>
      new Promise (res, rej)=>
        im = new mapnik.Image @size.width*2, @size.height*2
        @_map.render im, opts, (e,m)->
          console.log opts
          rej(e) if e?
          console.log "Done rendering map"
          res(m)

  setBounds: (bbox)->
    ## Can use an envelope feature or geometry
    bounds = boundsFromEnvelope bbox
    # Update bounding box size according to map zoom settings
    @_map.extent = bounds
    @extent = @_map.extent
    # Scale is equal for both x and y obviously
    @scale = @size.width/(@extent[2]-@extent[0])
    @_proj = new mapnik.Projection @_map.srs

  boundingPolygon: ->
    bboxPolygon(@extent)

  projection: (d)=>
    v = @_proj.forward(d)
    @transform(v)

  geoDimensions: =>
    # Get the width and height in map unit
    e = @extent
    { width: e[2]-e[0], height: e[3]-e[1] }

  createFeatures: (classname, opts)=>
    # Basic method to create a selection of features
    # that can be styled using css.
    opts ?= {}
    opts.geographic ?= true
    pathGenerator = if opts.geographic \
                then @geoPath else @path
    container = @dataArea

    fn = {}
    fn.data = (data)->
      # Returns selection
      el_ = container.append 'g'
        .attrs class: classname
      sel = el_.selectAll "path.#{classname}"
        .data data

      sel.enter()
        .append 'path'
        .attrs
          d: pathGenerator
    return fn

  transform: (d)=>
    [(d[0]-@extent[0])*@scale,(@extent[3]-d[1])*@scale]

  __setupGeoPath: ->
    # Must be in lat/lon to use geo path
    _proj = @projection
    trans = d3.geoTransform point: (x,y)->
      v = _proj [x,y]
      @stream.point v[0],v[1]
    d3.geoPath().projection trans

  geoPath: (d)=>
    @_geoPath ?= @__setupGeoPath()
    @_geoPath(d)

  __pathGenerator: =>
    # Must be in lat/lon to use geo path
    _proj = @transform
    trans = d3.geoTransform point: (x,y)->
      v = _proj [x,y]
      @stream.point v[0],v[1]
    d3.geoPath().projection trans

  path: (d)=>
    # A path in projected coordinates
    @_path ?= @__pathGenerator()
    @_path(d)

  scaleComponent: (opts)=>
    # A component for a d3 svg scale
    buildScale = require './scale'
    _map = @
    return (el)->buildScale(el,_map,opts)

  render: (fn)->
    # Render a cacheable map to a filename
    # Only render the map if the file doesn't exist
    if not fileExists(fn)
      im = @_map.renderSync {format: 'png'}
      dir = path.dirname fn
      if not fs.existsSync dir
        fs.mkdirSync dir
      fs.writeFileSync fn,im
    @filename = fn
    return fn

  renderAsync: (fn, variables={})->
    # Render a cacheable map to a filename
    # Only render the map if the file doesn't exist
    {writeFile} = Promise.promisify fs

    variables.lowerBound = 0
    variables.upperBound = 300

    if fileExists(fn)
      @filename = Promise.resolve fn
    @filename = @__render {format: 'png', variables: variables}
      .tap ->
        dir = path.dirname fn
        if not fs.existsSync dir
          fs.mkdirSync dir
      .then (im)->
        writeFile fn,im
        fn

  renderToObjectUrl: (variables)->
    @filename = @__render {format: 'png', variables}
      .then (im)->
        new Promise (res,rej)->
          console.log "Encoded"
          im.encode 'png', {}, (e,c)->res(c)
      .then (im)->
        blob = new Blob [im], {type: 'image/png'}
        URL.createObjectURL(blob)

  waitForImages: =>
    new Promise (res)=>
      @image.on 'load', res

  create: (el, opts={})=>
    ###
    # Returns a promise of an element
    ###
    # Should wrap this to take a d3 selection or node
    console.log "Beginning to render map"
    el.attrs @size
    @el = el

    opts.variables ?= {}
    if not @filename?
      @renderToObjectUrl(opts.variables)

    p = @filename.then (filename)=>
      defs = el.append 'defs'

      cp = "map-bounds"
      defs.append 'rect'
          .attrs @size
          .attrs id: cp

      defs.append 'clipPath'
        .attr 'id', "mapClip"
        .append 'use'
        .attr 'xlink:href',"##{cp}"

      @image = el.append 'image'
        .attr 'xlink:href', filename
        .attrs @size

      @dataArea = el.append 'g'
        .attrs
          class: 'data-area'
          'clip-path': "url(#mapClip)"

      @overlay = el.append 'g'
        .attrs
          class: 'overlay'
          'clip-path': "url(#mapClip)"

      if not opts.scale?
        return @

      if typeof opts.scale is "boolean"
        opts.scale = {}

      opts.scale.width ?= @size.width/3
      @overlay.append 'g'
        .attr 'class', 'scale'
        .attr 'transform',"translate(10 #{@size.height-10})"
        .call @scaleComponent(opts.scale)
      return @

    p.then @waitForImages

module.exports = StaticMap
