fs = require 'fs'
path = require 'path'
carto = require "carto"
_ = require 'underscore'

parsers = require './parsers'

parseMML = (obj, fileName)->
  dir = path.dirname fileName

  doIfString = (func)->(x)->
    return x unless _.isString x
    filename = path.resolve(path.join dir, x)
    contents = fs.readFileSync(filename, 'utf8')
    return func(x, content)

  # Something here involving layers

  func = doIfString (id, data)->{ id, data }
  obj.Stylesheet = obj.Stylesheet.map func

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

    try
      fp = global.resolve fn
    catch e
      fp = path.resolve fn

    txt = fs.readFileSync fp, 'utf8'
    parser = layerParsers[ext.slice(1)]
    layer.xml = parser txt, fp

  # Set name from ID if not defined
  layer.name ?= layer.id

  layer # {xml, **opts}
