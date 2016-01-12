fs = require 'fs'
path = require 'path'

parseYaml = (text)->
  yaml = require 'js-yaml'
  yaml.safeLoad text

registry =
  yaml: parseYaml
  yml: parseYaml
  json: JSON.parse

module.exports = (fn)->
  # Returns a configuration object
  # given a config file (currently only YAML).
  ext = path.extname fn
  dir = path.dirname fn

  method = registry[ext.slice(1)]
  contents = fs.readFileSync fn,'utf8'
  cfg = method contents

  # Check if we have a map config, or a more general
  # configuration file with a `map` section
  if not cfg.layers?
    cfg = cfg.map

  # Function to determine path
  specializePath = (fn)->
    # Relative paths are taken to be
    # with respect to config file
    if path.isAbsolute fn
      return fn
    else
      p = path.join dir,fn
      return path.normalize p

  cfg.layers.forEach (d)->
    # Make paths relative to config file
    d.filename = specializePath d.filename

  # Convert from lon,lat representation to
  # leaflet's internal lat,lon
  if cfg.center?
    cfg.center = [cfg.center[1],cfg.center[0]]

  return cfg


