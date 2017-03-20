d3 = require 'd3'
style = require './default.styl'

roundToNearest = (d,i=1)->
    Math.round(d/i) * i

order = (d)->
  Math.log(d) * Math.LOG10E | 0

module.exports = (el,map, opts={})->
  scale = map.scale
  opts.margin ?= 10
  opts.height ?= 5
  opts.ndivs ?= 5
  opts.unitMargin ?= 20
  opts.backgroundMargin ?= 20
  pts = [0,opts.width]

  initGuess = opts.width/scale
  o = order(initGuess)
  rounder = 5*Math.pow(10,o-1)
  geoSize = roundToNearest(initGuess, rounder)
  width = geoSize*scale

  ndivs = width/rounder

  label = 'm'
  # Switch to km if large
  if geoSize > 2000
    geoSize /= 1000
    label = 'km'

  console.log "Scale width: #{geoSize} #{label}"
  x = d3.scaleLinear()
    .domain [0,geoSize]
    .range [0,width]
    .nice()

  ticks = x.ticks(opts.ndivs)
  width = x(ticks[ticks.length-1])

  tickPairs = d3.pairs ticks

  bkg = el.append 'rect'
    .attrs class: 'background'

  g = el.append 'g'

  g.append 'rect'
    .attrs
      class: 'scale-background'
      height: opts.height
      width: width
      fill: 'white'

  sel = g.append 'g'
    .attrs class: 'scale-overlay'
    .selectAll 'rect'
    .data tickPairs

  sel.enter()
    .append 'rect'
    .classed 'even', (d,i)->i%2
    .attrs
      x: (d)->x(d[0])
      width: (d)->x(d[1])-x(d[0])
      height: opts.height

  labels = g.append 'g'
    .attrs class: 'tick-labels'
    .selectAll 'text'
    .data ticks

  margin = 5

  labels.enter()
    .append 'text'
    .text (d,i)->
      if i == ticks.length-1
        return "    #{d} #{label}"
      d
    .attrs
      x: x
      y: -margin

  #g.append 'text'
    #.text label
    #.attrs
      #class: 'unit-label'
      #x: width+opts.unitMargin
      #y: -margin


  h = map.size.height-opts.margin
  g.attr "transform", "translate(0, 0)"
    .attr 'class', 'map-scale'

  bbox = g.node().getBBox()

  bkg
    .attrs
      x: -20
      y: -15
      width: bbox.width+20
      height: bbox.height+20

  el.attrs 'transform': "translate(#{opts.margin}, #{h})"


