/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require("fs");
const path = require("path");
const _ = require("underscore");

const parsers = require("./parsers");
const configureLayer = require("./map");

module.exports = function (cfg) {
  if (cfg == null) {
    cfg = {};
  }
  if (_.isString(cfg)) {
    const fn = cfg;
    // Returns a configuration object
    // given a config file (currently only YAML).
    const ext = path.extname(fn);
    const dir = path.dirname(fn);

    const method = parsers[ext.slice(1)];
    const contents = fs.readFileSync(fn, "utf8");
    cfg = method(contents);
    if (cfg.basedir == null) {
      cfg.basedir = dir;
    }
  }

  const basedir = cfg.basedir || "";
  // Function to resolve pathnames
  const resolve = function (fn) {
    if (path.isAbsolute(fn)) {
      return fn;
    } else {
      return path.join(basedir, fn);
    }
  };

  // Check if we have a map config, or a more general
  // configuration file with a `map` section
  if (cfg.layers == null) {
    cfg = cfg.map;
  }

  cfg.layers = cfg.layers.map((d, i) => configureLayer(d));

  // Convert from lon,lat representation to
  // leaflet's internal lat,lon
  if (cfg.center != null) {
    cfg.center = [cfg.center[1], cfg.center[0]];
  }

  return cfg;
};
