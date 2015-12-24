Spine = require "spine"
$ = require "jquery"
Spine.$ = $
L = require "leaflet"
path = require 'path'
global.L = L

MapnikLayer = require './mapnik-layer'
setupProjection = require "./projection"

class Map extends Spine.Controller
  class: "viewer"
  defaults:
    tileSize: 256
  constructor: ->
    super
    @config = app.config.map
    for k,v of @defaults
      @config[k] = v unless @config[k]?

    @config.layers.forEach (d)->
      # Make paths relative to config file
      d.filename = app.config.path d.filename

    @visibleControls = ["layers","scale"] if not @visibleControls?
    @layers =
      baseMaps: {}
      overlayMaps: {}
    @render()

  render: ->
    @setupMap()

  invalidateSize: =>
    # Shim for flexbox
    @leaflet.invalidateSize()

  setHeight: ->
    @el.height window.innerHeight

  extentChanged: =>
    @trigger "extents", @leaflet.getBounds()

  setupMap: =>

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
      boxSelect: true

    @addMapnikLayers()
    @createControls()

    if @wmts?
      getData()
        .then @addWMTSLayers

    @leaflet.on "viewreset dragend", @extentChanged

  addMapnikLayers: =>

    layers = @config.layers

    @visibleLayers = []

    for cfg in layers
      fn = cfg.filename
      ext = path.extname fn
      id = path.basename fn, ext
      sz = cfg.tileSize or @config.tileSize
      l = new MapnikLayer fn, tileSize: sz
      l.id = id

      # Add to visible layers if there are
      # no visible layers currently set
      if not @visibleLayers.length
        @visibleLayers.push id

      @layers.overlayMaps[cfg.name] = l
      if @visibleLayers.indexOf(id) != -1
         l.addTo @leaflet

    _ = =>
      # Update cached layer information when
      # map is changed
      @visibleLayers = (v.id for k,v of @leaflet._layers)

    @leaflet.on 'layeradd layerremove', _

  createControls: =>
    console.log @layers

    layers = new L.Control.Layers @layers.baseMaps, @layers.overlayMaps,
      position: "topleft"

    @controls =
      layers: layers
      scale: L.control.scale
        maxWidth: 250,
        imperial: false

    for k in @visibleControls
      @controls[k].addTo @leaflet

  setBounds: (b)=>
    @leaflet.fitBounds(b)

  getBounds: =>
    b = @leaflet.getBounds()
    out = [
      [b._southWest.lat, b._southWest.lng]
      [b._northEast.lat, b._northEast.lng]]

module.exports = Map
