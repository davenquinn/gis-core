d3 = require 'd3'

# Maybe should use a more standardized
# version of this module
xml2json = require 'xml2json'

url = 'http://localhost:8000/tiles/wmts/1.0.0/WMTSCapabilities.xml'

doRequest = ->
  xo = d3.xhr(url)
  new Promise (resolve, reject)->
    xo.get (e,d)->
      if e then reject(e) else resolve(d)

convertToJSON = (response)->
  _ = xml2json.toJson response.responseText
  JSON.parse _

getLayerData = (d)->
  c = d.Capabilities.Contents

  tileSets = {}
  for ts in c.TileMatrixSet
    id = ts['ows:Identifier']
    tileSets[id] = ts

  console.log d
  layers = c.Layer
  for l in layers
    ts = l.TileMatrixSetLink.TileMatrixSet
    l.TileMatrixSet = tileSets[ts]

  return layers

createLayers = (layers)->
  # Create leaflet layers from WMTS datasources
  output = {}
  for l in layers
    _ = 'ows:Identifier'
    # Setup layers
    tmsid = l.TileMatrixSet[_]
    url = l.ResourceURL.template
      .replace '{TileMatrixSet}',tmsid
      .replace 'TileMatrix','z'
      .replace 'TileCol','x'
      .replace 'TileRow','y'

    tm = l.TileMatrixSet.TileMatrix


    id = l[_]
    lyr = L.tileLayer url,
      minZoom: Number(tm[0][_])
      maxZoom: Number(tm[tm.length-1][_])
      tileSize: tm[0].TileWidth
      continuousWorld: true
      detectRetina: true

    lyr.id = id
    name = l['ows:Title']
    output[name] = lyr
  return output

module.exports = ->
  doRequest()
    .then convertToJSON
    .then getLayerData
    .then createLayers
