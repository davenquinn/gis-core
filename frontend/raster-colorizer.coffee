index = {
  defaultColor: "raster-colorizer-default-color"
  mode: "raster-colorizer-default-mode"
  epsilon: "raster-colorizer-epsilon"
  scaling: 'raster-scaling'
  opacity: 'raster-opacity'
  compOp: 'comp-op'
  stops: 'raster-colorizer-stops'
}

defaults = {
  mode: 'linear'
  scaling: 'bilinear'
  opacity: 1
}

RasterColorizer = (name, scale, opts={})->
  opts.extend ?= 0

  if opts.ndivs?
    tickValues = scale.ticks opts.ndivs
  else
    tickValues = scale.domain()

  if opts.extend > 0
    tickValues.unshift tickValues[0]-opts.extend
    tickValues.push tickValues[tickValues.length-1]+opts.extend

  console.log tickValues
  # Create Stops
  stops = tickValues.map (val)->
    "    stop(#{val}, #{scale(val)})"
  opts.stops = "\n"+stops.join('\n')

  interior = ""

  for k,v of defaults
    opts[k] ?= v

  for k,value of opts
    key = index[k]
    continue unless key
    st = "  #{key}: #{value};\n"
    interior += st

  data = "#{name} {\n#{interior}}\n"
  id = name.replace("#","")
  obj = {id, data}
  obj.scale = scale
  return obj

module.exports = RasterColorizer
