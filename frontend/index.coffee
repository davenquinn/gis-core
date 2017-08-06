mapnik = require 'mapnik'
mapnikPool = require 'mapnik-pool'

pooledMapnik = mapnikPool mapnik
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

module.exports =
  Map: require './map'
  MapnikLayer: require './mapnik-layer'
  Leaflet: require 'leaflet'
  StaticMap: require './static'
  mapnik: mapnik
