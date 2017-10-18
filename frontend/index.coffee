mapnik = require 'mapnik'
mapnikPool = require 'mapnik-pool'

pooledMapnik = mapnikPool mapnik
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

{MapStyle, PostGISLayer} = require './map-style'

module.exports = {
  Map: require './map'
  MapnikLayer: require './mapnik-layer'
  StaticMap: require './static'
  mapnik
}
