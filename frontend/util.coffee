getLeaflet = ->
  if window?
    return require 'leaflet'
  return require 'leaflet-headless'

module.exports = {getLeaflet}
