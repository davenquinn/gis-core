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
  opts.backgroundMargin ?= 20
  opts.standalone ?= true
  opts.backgroundColor ?= 'white'

  # Filled background
  opts.filledBackground ?= not opts.standalone

  pts = [0,opts.width]

  initGuess = opts.width/scale
  o = order(initGuess)
  rounder = 5*Math.pow(10,o-1)
  geoSize = roundToNearest(initGuess, rounder)
  width = geoSize*scale

  ndivs = width/rounder
  opts.ndivs ?= 5 - ndivs

  label = 'm'
  # Switch to km if large
  if geoSize > 1500
    geoSize /= 1000
    label = 'km'

  console.log "Scale width: #{geoSize} #{label}"
  x = d3.scaleLinear()
    .domain [0,geoSize]
    .range [0,width]
    .nice()

  if opts.filledBackground
    bkg = el.append 'rect'
      .attrs class: 'background'

  # Guess number of ticks from size

  ticks = x.ticks(opts.ndivs)
  width = x(ticks[ticks.length-1])

  tickPairs = d3.pairs ticks

  g = el.append 'g'
    .attr 'class', 'map-scale'

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
    .selectAll 'text.label'
    .data ticks

  margin = 5

  labels.enter()
    .append 'text'
    .text (d,i)->d
    .attrs
      class: 'label'
      x: x
      y: -margin

  # Guess unit margin
  sel = d3.select "g.tick-labels text.label:last-child"
  v = sel.data()[0]
  nchars = "#{v}".length
  w = sel.node().getBBox().width
  charWidth = w/nchars
  offs = (nchars/2+1)*charWidth
  console.log offs
  opts.unitMargin ?= offs

  g.append 'text'
    .text label
    .attrs
      class: 'unit-label'
      x: width+opts.unitMargin
      y: -margin



  g.attr "transform", "translate(0, 0)"
    .attr 'class', 'map-scale'

  bbox = g.node().getBBox()

  if bkg?
    bkg
      .attrs
        x: -20
        y: -19
        width: bbox.width+20
        height: bbox.height+20

  if opts.standalone
    # TODO: This should be calculated based on scale parameters
    # but is currently imposed.
    el.attrs 'transform': 'translate(10,15)'
  else
    h = map.size.height-opts.margin
    el.attrs 'transform': "translate(#{opts.margin}, #{h})"

