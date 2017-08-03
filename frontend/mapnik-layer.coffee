mapnik = require 'mapnik'
mapnikPool = require 'mapnik-pool'
L = require 'leaflet'

pooledMapnik = mapnikPool mapnik
mapnik.register_default_fonts()
mapnik.register_default_input_plugins()

coordString = (coords)->
  "x: #{coords.x}, y: #{coords.y}, zoom: #{coords.z}"

class MapnikLayer extends L.GridLayer
  constructor: (@id, xml, options)->
    super()
    @options.updateWhenIdle = true
    @options.verbose ?= false
    @initialize options

    @pool = pooledMapnik.fromString xml, size: @options.tileSize
    @log "Created map pool"

  log: ->
    if @options.verbose
      console.log "(#{@constructor.name})", arguments...

  createTile: (coords, cb)->
    cs =  coordString(coords)

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
      console.log "Acquired map from pool"
      if e
        if map?
          pool.release map
        cb e
        return
      if not @_zooming and @_map.getZoom() != coords.z
        @log "Tile at wrong zoom level"
        pool.release map
        cb Error("Tile at wrong zoom level")
        return

      map.width = map.height = scaledSize
      im = new mapnik.Image(map.width,map.height)

      map.extent = box
      map.render im, {scale: r}, (err,im) =>
        if err then throw err
        i_ = im.encodeSync 'png'
        blob = new Blob [i_], {type: 'image/png'}
        url = URL.createObjectURL(blob)

        tile.src = url
        tile.onload = =>
          URL.revokeObjectURL(url)
        console.log "Releasing map back to pool"
        pool.release map
        cb null, tile

    return tile

  onAdd: (map)->
    @log "Adding to ", map
    if not @options.tileSize?
      @options.tileSize = map.config.tileSize or 256

    # We want to be able to check if we are currently
    # zooming
    @_zooming = false
    map.on "zoomstart",=>
      @_zooming = true
    map.on "zoomend",=>
      @_zooming = false

    super map

module.exports = MapnikLayer
