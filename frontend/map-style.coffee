{readFileSync} = require 'fs'
{safeLoad} = require 'js-yaml'
path = require 'path'
{Renderer} = require 'carto'
callsite = require 'callsite'
{existsSync} = require 'fs'
_ = require 'underscore'

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
    for style in opts.styles
      ### Try getting locally first ###
      if _.isString style
        style = @__getNamedStyle style
      @Stylesheet.push style

  __getNamedStyle: (id)=>
    sourceFile = null

    if id.endsWith '.mss'
      console.log "Checking path #{id} for stylesheet"
      sourceFile = id if existsSync id

    sourceFile ?= path.join @constructor.stylesheetDir, "#{id}.mss"

    {name} = path.parse sourceFile
    data = readFileSync(sourceFile,'utf8')
    return {id: name, data, sourceFile}

  toXml: =>
    cartoRenderer.render @

module.exports = MapStyle
