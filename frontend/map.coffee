L = require "leaflet"
parseConfig = require './config'
MapnikLayer = require './mapnik-layer'
TestLayer = require './test-layer'
setupProjection = require "./projection"

defaultOptions =
  tileSize: 256
  zoom: 0
  attributionControl: false
  continuousWorld: true
  debounceMoveend: true

class Map extends L.Map
  constructor: (el,options)->
    cfg = parseConfig options

    # Keep mapnik layer configs separate from
    # other layers (this is probably temporary)
    lyrs = {}
    for lyr in cfg.layers
      console.log lyr
      lyrs[lyr.name] = new MapnikLayer lyr.xml
    options.mapnikLayers = lyrs
    cfg.layers = []

    # Set options (values defined in code
    # take precedence).
    for k,v of cfg
      options[k] ?= v

    if options.projection?
      s = options.projection
      projection = setupProjection s,
        minResolution: options.resolution.min # m/px
        maxResolution: options.resolution.max # m/px
        bounds: options.bounds
      options.crs = projection

    for k,v of defaultOptions
      if not options[k]?
        options[k] = v

    @initialize el, options
    @addMapnikLayers()

  addMapnikLayers: (name)=>
    layers = @options.mapnikLayers
    if name?
      lyr = layers[name]
    else
      # Add the first layer (arbitrarily)
      for k,l of layers
        l.addTo @
        break

  addLayerControl: (baseLayers, overlayLayers)=>
    lyrs = @options.mapnikLayers
    for k,v of baseLayers
      lyrs[k] = v
    ctl = new L.Control.Layers lyrs, overlayLayers,
      position: "topleft"
    ctl.addTo @

  addScalebar: =>
    scale = new L.Control.Scale
      maxWidth: 250,
      imperial: false
    scale.addTo @


module.exports = Map
