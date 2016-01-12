$ = require "jquery"
L = require "leaflet"
path = require 'path'
global.L = L
configFromFile = require './config'

MapnikLayer = require './mapnik-layer'
setupProjection = require "./projection"

class Map extends L.Map
  constructor: (el,options)->
    window.map = @
    if options.configFile?
      cfg = configFromFile(options.configFile).map
      delete options.configFile

      # Keep mapnik layer configs separate from
      # other layers (this is probably temporary)
      options.mapnikLayers = cfg.layers
      delete cfg.layers

      # Set options (values defined in code
      # take precedence).
      for k,v of cfg
        options[k] = v unless options[k]?

    if options.projection?
      s = options.projection
      projection = setupProjection s,
        minResolution: options.resolution.min # m/px
        maxResolution: options.resolution.max # m/px
        bounds: options.bounds
      options.crs = projection

    if not options.tileSize?
      options.tileSize = 256

    console.log options
    @initialize el, options
    @setupBaseLayers()

  setupBaseLayers: ->
    @baseLayers = {}
    layers = @options.mapnikLayers
    for cfg in layers
      l = new MapnikLayer cfg.filename
      @baseLayers[cfg.name] = l
      l.addTo @

module.exports = Map
