d3 = require "d3"
L = require "leaflet"

class DataLayer extends L.SVG
  constructor: ->
    super
    @initialize padding: 0.1

  setupProjection: ->
    f = @projectPoint
    @projection = d3.geo.transform
      point: (x,y)->
        point = f(x,y)
        return @stream.point point.x, point.y

    @path = d3.geo.path().projection(@projection)

  projectPoint: (x,y)=>
    @_map.latLngToLayerPoint(new L.LatLng(y,x))

  onAdd: ->
    super
    @setupProjection()
    @svg = d3.select @_container
      .classed "data-layer", true
      .classed "leaflet-zoom-hide", true
    @_map.on "viewreset", @resetView

  resetView: ->

module.exports = DataLayer
