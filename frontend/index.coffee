mapnik = require 'mapnik'
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()
mapnikPool = require 'mapnik-pool'
mapnik.pool = mapnikPool mapnik

module.exports =
  Map: require './map'
  MapnikLayer: require './mapnik-layer'
  Leaflet: require 'leaflet'
  StaticMap: require './static'
  mapnik: mapnik
