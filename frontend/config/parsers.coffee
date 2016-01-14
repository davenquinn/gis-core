parseYaml = (text)->
  yaml = require 'js-yaml'
  yaml.safeLoad text

module.exports =
  yaml: parseYaml
  yml: parseYaml
  json: JSON.parse
