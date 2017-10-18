mapnik = require 'mapnik'
mapnikPool = require 'mapnik-pool'

pooledMapnik = mapnikPool mapnik
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

try
  Map = require './map'
  MapnikLayer = require './mapnik-layer'
catch
  Map = null
  MapnikLayer = null

module.exports = {
  Map, MapnikLayer
  StaticMap: require './static'
}
