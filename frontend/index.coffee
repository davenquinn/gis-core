mapnik = require 'mapnik'
mapnik.pool = mapnikPool mapnik
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()
mapnikPool = require 'mapnik-pool'

module.exports =
  Map: require './map'
  MapnikLayer: require './mapnik-layer'
  Leaflet: require 'leaflet'
  StaticMap: require './static'
  mapnik: mapnik
