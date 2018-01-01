mapnik = require 'mapnik'
mapnikPool = require 'mapnik-pool'

pooledMapnik = mapnikPool mapnik
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

{getLeaflet} = require './util'
L = getLeaflet()

module.exports = {
  Map: require './map'
  MapnikLayer: require './mapnik-layer'
  Leaflet: L
  StaticMap: require './static'
  MapStyle: require './map-style'
  require('./raster-colorizer')...
}
