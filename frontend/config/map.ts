/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require("fs");
const path = require("path");
const carto = require("carto");
const _ = require("underscore");

const parsers = require("./parsers");

const parseMML = function (data, fileName, cfg) {
  let Layers;
  if (cfg == null) {
    cfg = {};
  }
  if (cfg.layers == null) {
    cfg.layers = process.env.MAPNIK_LAYERS;
  }
  if (cfg.layers != null) {
    // A layers file
    const s = fs.readFileSync(cfg.layers, "utf8");
    Layers = parsers.yaml(s);
  }

  if (Layers != null) {
    data.Layer = data.Layer.map(function (id) {
      if (typeof id === "object") {
        return id;
      }
      const obj = Layers[id] || {};
      obj.name = id;
      obj.id = id;
      return obj;
    });
  }

  if (cfg.styles != null) {
    data.Stylesheet = data.Stylesheet.concat(cfg.styles);
  }
  console.log(data.Stylesheet);

  const rfn = function (acc, x) {
    if (typeof x !== "string") {
      return acc + x.data;
    }
    const fn = path.join(path.dirname(fileName), x);
    return acc + fs.readFileSync(fn, "utf8");
  };

  const val = data.Stylesheet.reduce(rfn, "");
  data.Stylesheet = [{ id: "style", data: val }];
  const renderer = new carto.Renderer();
  return renderer.render(data);
};

const parseYMML = (txt, fn, cfg) => parseMML(parsers.yaml(txt), fn, cfg);

const layerParsers = {
  xml(d) {
    return d;
  },
  mml(d, fn, cfg) {
    return parseMML(JSON.parse(d), fn, cfg);
  },
  yaml: parseYMML,
  ymml: parseYMML,
};

const loadCfg = function (layer, cfg) {
  let fp;
  if (_.isString(layer)) {
    layer = { filename: layer };
  }

  const fn = layer.filename;
  const ext = path.extname(fn);
  if (layer.id == null) {
    layer.id = path.basename(fn, ext);
  }

  try {
    fp = global.resolve(fn);
  } catch (e) {
    fp = path.resolve(fn);
  }

  const txt = fs.readFileSync(fp, "utf8");
  const parser = layerParsers[ext.slice(1)];
  layer.xml = parser(txt, fp, cfg);

  // Set name from ID if not defined
  if (layer.name == null) {
    layer.name = layer.id;
  }

  return layer; // {xml, **opts}
};

module.exports = loadCfg;
