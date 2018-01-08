try
  h = if window? then 'leaflet' else 'leaflet-headless'
  L = require h
catch e
  console.log "Couldn't load leaflet"
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
  constructor: (el,opts)->
    console.log opts
    c = null
    c ?= opts.configFile
    c = opts unless c?
    cfg = parseConfig c
    # Keep mapnik layer configs separate from
    # other layers (this is probably temporary)
    lyrs = {}
    for lyr in cfg.layers
      lyrs[lyr.name] = new MapnikLayer lyr.name, lyr.xml, verbose: true
    options = {}
    options.mapnikLayers = lyrs

    # Set options (values defined in code
    # take precedence).
    options.layers = []
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

    super el, options
    @addMapnikLayers options.initLayer or null

  addMapnikLayers: (name)=>
    layers = @options.mapnikLayers
    if name?
      lyr = layers[name]

    if not lyr?
      # Add the first layer (arbitrarily)
      for k,l of layers
        lyr = l
        break

    console.log @options
    console.log lyr
    lyr.addTo @

  addLayerControl: (baseLayers, overlayLayers)=>
    console.log @options
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
