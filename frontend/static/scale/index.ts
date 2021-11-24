/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const d3 = require("d3");
//style = require './default.styl'

const roundToNearest = function (d, i) {
  if (i == null) {
    i = 1;
  }
  return Math.round(d / i) * i;
};

const order = (d) => (Math.log(d) * Math.LOG10E) | 0;

module.exports = function (el, map, opts) {
  let bkg;
  if (opts == null) {
    opts = {};
  }
  const { scale } = map;
  if (opts.margin == null) {
    opts.margin = 10;
  }
  if (opts.height == null) {
    opts.height = 5;
  }
  if (opts.backgroundMargin == null) {
    opts.backgroundMargin = 20;
  }
  if (opts.standalone == null) {
    opts.standalone = true;
  }
  if (opts.backgroundColor == null) {
    opts.backgroundColor = "white";
  }

  // Filled background
  if (opts.filledBackground == null) {
    opts.filledBackground = !opts.standalone;
  }

  const pts = [0, opts.width];

  const initGuess = opts.width / scale;
  const o = order(initGuess);
  const rounder = 5 * Math.pow(10, o - 1);
  let geoSize = roundToNearest(initGuess, rounder);
  let width = geoSize * scale;

  const ndivs = width / rounder;
  if (opts.ndivs == null) {
    opts.ndivs = 5 - ndivs;
  }

  let label = "m";
  // Switch to km if large
  if (geoSize > 1500) {
    geoSize /= 1000;
    label = "km";
  }

  console.log(`Scale width: ${geoSize} ${label}`);
  const x = d3.scaleLinear().domain([0, geoSize]).range([0, width]).nice();

  if (opts.filledBackground) {
    bkg = el.append("rect").attrs({ class: "background" });
  }

  // Guess number of ticks from size

  const ticks = x.ticks(opts.ndivs);
  width = x(ticks[ticks.length - 1]);

  const tickPairs = d3.pairs(ticks);

  const g = el.append("g").attr("class", "map-scale");

  g.append("rect").attrs({
    class: "scale-background",
    height: opts.height,
    width,
    fill: "white",
  });

  let sel = g
    .append("g")
    .attrs({ class: "scale-overlay" })
    .selectAll("rect")
    .data(tickPairs);

  sel
    .enter()
    .append("rect")
    .classed("even", (d, i) => i % 2)
    .attrs({
      x(d) {
        return x(d[0]);
      },
      width(d) {
        return x(d[1]) - x(d[0]);
      },
      height: opts.height,
    });

  const labels = g
    .append("g")
    .attrs({ class: "tick-labels" })
    .selectAll("text.label")
    .data(ticks);

  const margin = 5;

  labels
    .enter()
    .append("text")
    .text((d, i) => d)
    .attrs({
      class: "label",
      x,
      y: -margin,
    });

  // Guess unit margin
  sel = d3.select("g.tick-labels text.label:last-child");
  const v = sel.data()[0];
  const nchars = `${v}`.length;
  const w = sel.node().getBBox().width;
  const charWidth = w / nchars;
  const offs = (nchars / 2 + 1) * charWidth;
  console.log(offs);
  if (opts.unitMargin == null) {
    opts.unitMargin = offs;
  }

  g.append("text")
    .text(label)
    .attrs({
      class: "unit-label",
      x: width + opts.unitMargin,
      y: -margin,
    });

  g.attr("transform", "translate(0, 0)").attr("class", "map-scale");

  const bbox = g.node().getBBox();

  if (bkg != null) {
    bkg.attrs({
      x: -20,
      y: -19,
      width: bbox.width + 20,
      height: bbox.height + 20,
    });
  }

  if (opts.standalone) {
    // TODO: This should be calculated based on scale parameters
    // but is currently imposed.
    return el.attrs({ transform: "translate(10,15)" });
  } else {
    const h = map.size.height - opts.margin;
    return el.attrs({ transform: `translate(${opts.margin}, ${h})` });
  }
};
