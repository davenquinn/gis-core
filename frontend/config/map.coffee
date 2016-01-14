fs = require 'fs'
path = require 'path'
_ = require 'underscore'

parsers =
  xml: (fn)->fs.readFileSync(fn,'utf8')

module.exports = (layer)->
  if _.isString layer
    layer = filename: layer
  console.log layer

  if layer.filename?
    fn = layer.filename
    ext = path.extname fn
    layer.id ?= path.basename fn, ext
    layer.xml = parsers[ext.slice(1)] fn


  # Set name from ID if not defined
  layer.name ?= layer.id

  console.log layer

  layer # {xml, **opts}
