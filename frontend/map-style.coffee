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
  Stylesheet: []
  Layer: []
  srs: null
  constructor: (opts={})->
    opts.srs ?= "+proj=tmerc +lat_0=17 +lon_0=76.5 +k=0.9996
        +x_0=0 +y_0=0 +a=3396190 +b=3376200 +units=m +no_defs"
    opts.layers ?= []
    opts.styles ?= []

    @srs ?= opts.srs
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
