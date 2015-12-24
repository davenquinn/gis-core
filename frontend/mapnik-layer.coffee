fs = require 'fs'
mapnik = require 'mapnik'
mapnikPool = require 'mapnik-pool'
L = require 'leaflet'

mapnik.register_default_fonts()
mapnik.register_default_input_plugins()
mPool = mapnikPool(mapnik)

class MapnikLayer extends L.GridLayer
  constructor: (mapfile, options)->
    @options.updateWhenIdle = true
    @initialize options

    _ = fs.readFileSync(mapfile, 'utf8')
    @pool = mPool.fromString _, size: @options.tileSize

  createTile: (coords)->
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
    pool.acquire (e,map)->
      if e then throw e
      map.width = map.height = scaledSize
      im = new mapnik.Image(map.width,map.height)

      map.extent = box
      map.render im, {scale: r}, (err,im) =>
        if err then throw err
        i_ = im.encodeSync 'png'
        blob = new Blob [i_], {type: 'image/png'}
        url = URL.createObjectURL(blob)

        tile.src = url
        tile.onload = ->
          URL.revokeObjectURL(url)
          _ = "x: #{coords.x}, y: #{coords.y}, zoom: #{coords.z}"
          console.log _
        pool.release map

    return tile

module.exports = MapnikLayer
