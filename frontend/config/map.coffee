fs = require 'fs'
path = require 'path'
carto = require "carto"
_ = require 'underscore'

parsers = require './parsers'

parseMML = (obj, fileName)->
  console.log obj
  dir = path.dirname fileName

  obj.Stylesheet = obj.Stylesheet.map (x)->
    if _.isString x
      fn = path.join dir, x
      x = fs.readFileSync(fn, 'utf8')
      return id: fn, data: x
    else
      return x

  renderer = new carto.Renderer
  return renderer.render(obj)

parseYMML = (txt, fn)->
  parseMML parsers.yaml(txt), fn

layerParsers =
  xml: (d)->d
  mml: (d,fn)->parseMML JSON.parse(d), fn
  yaml: parseYMML
  ymml: parseYMML

module.exports = (layer)->
  if _.isString layer
    layer = filename: layer
  console.log layer

  if layer.filename?
    fn = layer.filename
    ext = path.extname fn
    layer.id ?= path.basename fn, ext
    txt = fs.readFileSync fn, 'utf8'
    parser = layerParsers[ext.slice(1)]
    layer.xml = parser txt, fn

  # Set name from ID if not defined
  layer.name ?= layer.id

  layer # {xml, **opts}
