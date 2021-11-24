/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const index = {
  defaultColor: "raster-colorizer-default-color",
  mode: "raster-colorizer-default-mode",
  epsilon: "raster-colorizer-epsilon",
  scaling: "raster-scaling",
  opacity: "raster-opacity",
  compOp: "raster-comp-op",
  stops: "raster-colorizer-stops",
};

const defaults = {
  mode: "linear",
  scaling: "bilinear",
  opacity: 1,
};

const ImageStretch = function (name, stops, opts, scale) {
  let k;
  if (stops == null) {
    stops = [0, 255];
  }
  if (opts == null) {
    opts = {};
  }
  if (opts.min == null) {
    opts.min = 0;
  }
  if (opts.max == null) {
    opts.max = 255;
  }
  if (scale == null) {
    scale = ["black", "white"];
  }
  if (scale instanceof Array) {
    if (stops[0] > opts.min) {
      stops.unshift(opts.min);
      scale.unshift("black");
    }
    if (stops[stops.length - 1] < opts.max) {
      stops.push(opts.max);
      scale.push("white");
    }
  }
  stops = stops.map(function (val, i) {
    const v = scale instanceof Array ? scale[i] : scale(val);
    return `    stop(${val}, ${v})`;
  });
  opts.stops = "\n" + stops.join("\n");

  // Begin building CartoCSS
  let interior = "";

  for (k in defaults) {
    const v = defaults[k];
    if (opts[k] == null) {
      opts[k] = v;
    }
  }

  for (k in opts) {
    const value = opts[k];
    const key = index[k];
    if (!key) {
      continue;
    }
    const st = `  ${key}: ${value};\n`;
    interior += st;
  }

  const data = `${name} {\n${interior}}\n`;
  const id = name.replace("#", "");
  const obj = { id, data };
  obj.scale = scale;
  return obj;
};

const RasterColorizer = function (name, scale, opts) {
  let tickValues;
  if (opts == null) {
    opts = {};
  }
  if (opts.extend == null) {
    opts.extend = 0;
  }

  if (opts.ndivs != null) {
    tickValues = scale.ticks(opts.ndivs);
  } else {
    tickValues = scale.domain();
  }

  if (opts.extend > 0) {
    tickValues.unshift(tickValues[0] - opts.extend);
    tickValues.push(tickValues[tickValues.length - 1] + opts.extend);
  }

  console.log(tickValues);

  return ImageStretch(name, tickValues, opts, scale);
};

module.exports = { RasterColorizer, ImageStretch };
