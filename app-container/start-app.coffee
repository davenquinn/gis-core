remote = require 'remote'
gis = require '../frontend'
L = require 'leaflet'

el = document.querySelector '#main'
window.app = remote.require "app"

map = new gis.Map el,
  configFile: app.configFile
  zoom: 2
  boxZoom: false
  continuousWorld: true
  debounceMoveend: true

layers = new L.Control.Layers map.baseLayers, {},
  position: "topleft"

scale = L.control.scale
  maxWidth: 250,
  imperial: false

scale.addTo map
layers.addTo map

console.log map

