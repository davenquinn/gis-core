L = require "leaflet"
proj4 = require "proj4"

setupProjection = (def, options)->
  options = options or {}
  unless 'resolutions' of options
    if not 'minResolution' of options
      throw "minResolution required if resolutions are not specified"
    res = []
    r = options.minResolution
    limit = options.maxResolution or 0.1
    while r > limit
      res.push r
      r /= 2
    options.resolutions = res

  p = proj4.Proj(def)
  if p.datum.a?
    # Allows resizing of scalebar (a bit hackish)
    L.CRS.Earth.R = p.datum.a

  # Setup geographic coordinate system
  geog =
    projName: 'longlat'
    a: p.datum.a
    b: p.datum.b
    no_defs: true
  gp = proj4.Proj geog

  projection = proj4 gp,p

  throw 'bounds required' unless 'bounds' of options
  _bounds = options.bounds
    .map projection.forward
    .map (d)-> L.point d[0], d[1]
  bounds = L.bounds _bounds

  Projection =
    bounds: bounds
    project: (ll)->
      out = projection.forward [ll.lng,ll.lat]
      new L.Point out[0],out[1]
    unproject: (pt)->
      out = projection.inverse [pt.x,pt.y]
      new L.LatLng out[1], out[0]

  return L.extend {}, L.CRS.Earth,
    code: 'IAU:950000'
    projection: Projection
    transformation: new L.Transformation 1, -bounds.min.x, -1, bounds.max.y
    scale: (zoom)-> 1/options.resolutions[zoom]
    wrapLng: null
    resolution: (zoom)->options.resolutions[zoom]

module.exports = setupProjection
