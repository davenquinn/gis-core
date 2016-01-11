$ = require "jquery"
L = require "leaflet"
path = require 'path'
global.L = L

MapnikLayer = require './mapnik-layer'
setupProjection = require "./projection"

class Map
  class: "viewer"
  defaults:
    tileSize: 256
  constructor: (@el,@config)->
    for k,v of @defaults
      @config[k] = v unless @config[k]?

    @layers =
      baseMaps: {}
      overlayMaps: {}

    s = @config.projection
    projection = setupProjection s,
      minResolution: @config.resolution.min # m/px
      maxResolution: @config.resolution.max # m/px
      bounds: @config.bounds

    @leaflet = new L.Map @el,
      center: @config.center
      zoom: 2
      crs: projection
      boxZoom: false
      continuousWorld: true
      debounceMoveend: true

    layers = @config.layers
    for cfg in layers
      l = new MapnikLayer cfg.filename
      @layers.baseMaps[cfg.name] = l
      l.addTo @leaflet

    layers = new L.Control.Layers @layers.baseMaps, @layers.overlayMaps,
      position: "topleft"

    scale = L.control.scale
      maxWidth: 250,
      imperial: false

    scale.addTo @leaflet
    layers.addTo @leaflet

module.exports = Map
