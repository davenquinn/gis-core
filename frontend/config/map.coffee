fs = require 'fs'
path = require 'path'
carto = require "carto"
_ = require 'underscore'

parsers = require './parsers'

parseMML = (data, fileName, cfg={})->
  cfg.layers ?= process.env.MAPNIK_LAYERS
  if cfg.layers? # A layers file
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

  if cfg.styles?
    data.Stylesheet = data.Stylesheet.concat(cfg.styles)
  console.log data.Stylesheet

  rfn = (acc, x)->
    if typeof x isnt 'string'
        return acc + x.data
    fn = path.join path.dirname(fileName), x
    return acc + fs.readFileSync(fn, 'utf8')

  val =  data.Stylesheet.reduce rfn, ""
  data.Stylesheet = [{id: 'style', data: val}]
  renderer = new carto.Renderer
  return renderer.render(data)

parseYMML = (txt, fn, cfg)->
  parseMML parsers.yaml(txt), fn, cfg

layerParsers =
  xml: (d)->d
  mml: (d,fn, cfg)->parseMML JSON.parse(d), fn, cfg
  yaml: parseYMML
  ymml: parseYMML

loadCfg = (layer, cfg)->
  if _.isString layer
    layer = filename: layer

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

module.exports = loadCfg
