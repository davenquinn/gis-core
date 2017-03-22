mapnik = require 'mapnik'
path = require 'path'
fs = require 'fs'
d3 = require 'd3'
buildScale = require './scale'
{fileExists} = require './util'
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

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

MPATH = "#{process.env.PROJECT_DIR}/versioned/application/config/maps/_compiled"
ECANNOTRENDER = "Can't render – layers could not be loaded."

class StaticMap
  constructor: (@size, bbox, name)->
    ###
    Can use bounding box or tuple of urx,ury,llx,lly
    ###
    name ?= "ortho"
    cfg = path.join(MPATH,"#{name}.xml")
    mapData = loadCfg cfg

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

  projection: (d)=>
    v = @_proj.forward(d)
    @transform(v)

  transform: (d)->
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

  scaleComponent: (opts)=>
    # A component for a d3 svg scale
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

  renderAsync: (fn)->
    # Render a cacheable map to a filename
    # Only render the map if the file doesn't exist
    {writeFile} = Promise.promisify fs

    if fileExists(fn)
      @filename = Promise.resolve fn
    @filename = @__render {format: 'png'}
      .tap ->
        dir = path.dirname fn
        if not fs.existsSync dir
          fs.mkdirSync dir
      .then (im)->
        writeFile fn,im
        fn

  renderToObjectUrl: ->
    @filename = @__render {format: 'png'}
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

    if not @filename?
      @renderToObjectUrl()

    @filename.then (filename)=>
      console.log filename
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

      if not opts.scale?
        return @
      opts.scale.width ?= @size.width/3
      el.append 'g'
        .attr 'class', 'scale'
        .attr 'transform',"translate(10 #{@size.height-10})"
        .call @scaleComponent(opts.scale)
      return @

module.exports = StaticMap
