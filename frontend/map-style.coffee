{readFileSync} = require 'fs'
{safeLoad} = require 'js-yaml'
path = require 'path'
{Renderer} = require 'carto'

cartoRenderer = new Renderer

class MapStyle
  ### A proxy for a CartoCSS stylesheet ###
  @layerDirectory: do ->
    text = readFileSync process.env.MAPNIK_LAYERS, 'utf8'
    safeLoad text
  @stylesheetDir: path.join(process.env.REPO_DIR,'map-styles','styles')
  srs: null
  constructor: (opts={})->
    @Layer ?= []
    @Stylesheet ?= []
    @srs ?= opts.srs
    opts.layers ?= []
    opts.styles ?= []

    @Layer = opts.layers.map (id)=>
      lyr = @constructor.layerDirectory[id] or {}
      lyr.name = id
      return lyr

    ### Add computed styles to stylesheet ###
    for id in opts.styles
      sourceFile = path.join @constructor.stylesheetDir, "#{id}.mss"
      data = readFileSync(sourceFile,'utf8')
      @Stylesheet.push {id, data, sourceFile}

  toXml: =>
    cartoRenderer.render @

module.exports = MapStyle
