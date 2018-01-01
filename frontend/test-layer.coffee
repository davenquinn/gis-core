{getLeaflet} = require './util'
L = getLeaflet()

coordString = (coords)->
  "x: #{coords.x}, y: #{coords.y}, zoom: #{coords.z}"

class TestLayer extends L.GridLayer
  constructor: (options)->
    super()
    @options.updateWhenIdle = true
    @options.verbose = true
    @initialize options

  log: =>
    if @options.verbose
      console.log "(#{@constructor.name})", arguments...

  createTile: (coords)=>
    cs =  coordString(coords)
    tile = document.createElement('canvas')
    ctx = tile.getContext('2d')
    tile.width = tile.height = 256
    ctx.fillStyle = 'white'
    ctx.fillRect(0, 0, 255, 255)
    ctx.fillStyle = 'black'
    ctx.fillText cs, 20, 20
    ctx.strokeStyle = 'red'
    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.lineTo(255, 0)
    ctx.lineTo(255, 255)
    ctx.lineTo(0, 255)
    ctx.closePath()
    ctx.stroke()
    @log "Rendering", cs
    return tile

  onAdd: (map)->
    @log "Adding to ", map
    if not @options.tileSize?
      @options.tileSize = map.config.tileSize or 256
    super map

module.exports = TestLayer

