{getLeaflet} = require './util'
L = getLeaflet()

d3 = null

class DataLayer extends L.SVG
  constructor: ->
    super
    # Specify a particular d3
    # object to enable event propagation
    # if submodules are defined.
    @d3 = @options.d3 or require 'd3'
    @initialize padding: 0.1

  setupProjection: =>
    f = @projectPoint
    @projection = @d3.geo.transform
      point: (x,y)->
        point = f(x,y)
        return @stream.point point.x, point.y

    @path = @d3.geo.path().projection(@projection)

  projectPoint: (x,y)=>
    @_map.latLngToLayerPoint(new L.LatLng(y,x))

  onAdd: =>
    super
    @setupProjection()
    @svg = @d3.select @_container
      .classed "data-layer", true
      .classed "leaflet-zoom-hide", true
    @_map.on "viewreset", @resetView

  resetView: ->

module.exports = DataLayer
