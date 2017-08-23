{readFileSync} = require 'fs'
{safeLoad} = require 'js-yaml'
path = require 'path'
{Renderer} = require 'carto'

cartoRenderer = new Renderer

class MapStyle
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
    #opts.layers ?= ['regional-ortho']
    #opts.styles ?= ['imagery']

    @srs ?= opts.srs
    @Layer = opts.layers.map (id)=>
      lyr = @constructor.layerDirectory[id] or {}
      lyr.name = id
      return lyr

    @Stylesheet = [{id:'style',data:''}]
    ### Add computed styles to stylesheet ###
    rfn = (style, id)=>
      fn = path.join @constructor.stylesheetDir, "#{id}.mss"
      data = readFileSync(fn,'utf8')
      return style+data

    @Stylesheet[0].data = opts.styles.reduce rfn, @Stylesheet[0].data

  toXml: =>
    cartoRenderer.render @

module.exports = MapStyle
