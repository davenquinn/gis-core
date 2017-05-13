fs = require 'fs'
path = require 'path'
_ = require 'underscore'

parsers = require './parsers'
configureLayer = require './map'

module.exports = (cfg={})->
  if _.isString cfg
    fn = cfg
    # Returns a configuration object
    # given a config file (currently only YAML).
    ext = path.extname fn
    dir = path.dirname fn

    method = parsers[ext.slice(1)]
    contents = fs.readFileSync fn,'utf8'
    cfg = method contents
    cfg.basedir ?= dir

  basedir = cfg.basedir or ""
  # Function to resolve pathnames
  resolve = (fn)->
    if path.isAbsolute fn
      return fn
    else
      return path.join basedir,fn

  # Check if we have a map config, or a more general
  # configuration file with a `map` section
  if not cfg.layers?
    cfg = cfg.map

  cfg.layers ?= []
  applyConfig = configureLayer(resolveFilename: resolve)
  cfg.layers = cfg.layers.map applyConfig

  # Convert from lon,lat representation to
  # leaflet's internal lat,lon
  if cfg.center?
    cfg.center = [cfg.center[1],cfg.center[0]]

  return cfg
