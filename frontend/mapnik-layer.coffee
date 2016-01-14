mapnik = require 'mapnik'
L = require 'leaflet'

coordString = (coords)->
  "x: #{coords.x}, y: #{coords.y}, zoom: #{coords.z}"

class MapnikLayer extends L.GridLayer
  constructor: (xml, options)->
    @options.updateWhenIdle = true
    @options.verbose = true
    @initialize options

    @pool = mapnik.pool.fromString xml,
      sync: true
      size: @options.tileSize

  log: =>
    if @options.verbose
      console.log "(#{@constructor.name})", arguments...

  createTile: (coords)=>
    cs =  coordString(coords)
    @log "Starting", cs

    r = window.devicePixelRatio or 1
    scaledSize = @options.tileSize * r

    tile = new Image
    tile.width = tile.height = scaledSize

    crs = @_map.options.crs
    bounds = crs.projection.bounds
    sz = @options.tileSize/ crs.scale(coords.z)

    ll =
      x: bounds.min.x + coords.x * sz
      y: bounds.max.y - (coords.y + 1) * sz
    ur =
      x: bounds.min.x + (coords.x + 1) * sz
      y: bounds.max.y - (coords.y) * sz
    box = [ll.x,ll.y,ur.x,ur.y]

    pool = @pool
    pool.acquire (e,map)=>
      if e then throw e
      map.width = map.height = scaledSize
      im = new mapnik.Image(map.width,map.height)

      map.extent = box
      @log "Rendering", cs
      map.render im, {scale: r}, (err,im) =>
        if err then throw err
        i_ = im.encodeSync 'png'
        blob = new Blob [i_], {type: 'image/png'}
        url = URL.createObjectURL(blob)

        tile.src = url
        tile.onload = ->
          URL.revokeObjectURL(url)
          console.log cs
        pool.release map

    return tile

  onAdd: (map)->
    @log "Adding to ", map
    if not @options.tileSize?
      @options.tileSize = map.config.tileSize or 256
    super map

module.exports = MapnikLayer
