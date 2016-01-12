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
  # Function to determine path
  cfg.path = (fn)->
    # Relative paths are taken to be
    # with respect to config file
    if path.isAbsolute fn
      return fn
    else
      p = path.join dir,fn
      return path.normalize p

  cfg.map.layers.forEach (d)->
    # Make paths relative to config file
    d.filename = cfg.path d.filename

  return cfg


