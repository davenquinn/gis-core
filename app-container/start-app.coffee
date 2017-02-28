{remote} = require 'electron'
gis = require '../frontend'
L = require 'leaflet'

el = document.querySelector '#main'

map = new gis.Map el,
  configFile: remote.app.configFile
  zoom: 2
  boxZoom: false
  continuousWorld: true
  debounceMoveend: true

map.addLayerControl()

scale = L.control.scale
  maxWidth: 250,
  imperial: false
scale.addTo map

