fs = require 'fs'
path = require 'path'
carto = require "carto"
_ = require 'underscore'

parsers = require './parsers'

parseMML = (data, fileName, cfg={})->
  if cfg.layers?
    s = fs.readFileSync cfg.layers, 'utf8'
    Layers = parsers.yaml(s)

  if Layers?
    data.Layer = data.Layer.map (id)->
      if typeof(id) is 'object'
        return id
      obj = Layers[id] or {}
      obj.name = id
      obj.id = id
      return obj

  data.Stylesheet = data.Stylesheet.map (x)->
      if typeof x isnt 'string'
          return id: x, data: x.data
      fn = path.join path.dirname(fileName), x
      d = fs.readFileSync(fn, 'utf8')
      return id: x, data: d

  renderer = new carto.Renderer
  return renderer.render(data)

parseYMML = (txt, fn, cfg)->
  parseMML parsers.yaml(txt), fn, cfg

layerParsers =
  xml: (d)->d
  mml: (d,fn, cfg)->parseMML JSON.parse(d), fn, cfg
  yaml: parseYMML
  ymml: parseYMML

module.exports = (layer, cfg)->
  if _.isString layer
    layer = filename: layer

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
    layer.xml = parser txt, fp, cfg

  # Set name from ID if not defined
  layer.name ?= layer.id

  layer # {xml, **opts}
