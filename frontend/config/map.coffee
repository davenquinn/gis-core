fs = require 'fs'
path = require 'path'

parsers =
  xml: (fn)->fs.readFileSync(fn,'utf8')

module.exports = (layer)->
  if layer.filename?
    fn = layer.filename
    ext = path.extname fn
    layer.id ?= path.basename fn, ext
    layer.xml = parsers[ext.slice(1)] fn
  # Parses each layer configuration into pairs of name, mapnik xml
  layer
