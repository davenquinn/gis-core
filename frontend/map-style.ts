/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const { readFileSync } = require("fs");
const { safeLoad } = require("js-yaml");
const path = require("path");
const { Renderer } = require("carto");
const callsite = require("callsite");
const { existsSync } = require("fs");
const _ = require("underscore");

const cartoRenderer = new Renderer();

class MapStyle {
  static initClass() {
    /* A proxy for a CartoCSS stylesheet */
    this.layerDirectory = (function () {
      const text = readFileSync(process.env.MAPNIK_LAYERS, "utf8");
      return safeLoad(text);
    })();
    this.stylesheetDir = path.join(
      process.env.REPO_DIR,
      "map-styles",
      "styles"
    );
    this.prototype.srs = null;
  }
  constructor(opts) {
    this.__getNamedStyle = this.__getNamedStyle.bind(this);
    this.toXml = this.toXml.bind(this);
    if (opts == null) {
      opts = {};
    }
    if (this.Layer == null) {
      this.Layer = [];
    }
    if (this.Stylesheet == null) {
      this.Stylesheet = [];
    }
    if (this.srs == null) {
      this.srs = opts.srs;
    }
    if (opts.layers == null) {
      opts.layers = [];
    }
    if (opts.styles == null) {
      opts.styles = [];
    }
    this.layers = opts.layers;
    this.styles = opts.styles;

    this.Layer = opts.layers.map((id) => {
      let lyr;
      if (_.isString(id)) {
        lyr = this.constructor.layerDirectory[id] || {};
        lyr.name = id;
      } else {
        lyr = id;
      }
      if (lyr.srs == null) {
        lyr.srs = this.srs;
      }
      console.log(lyr);
      return lyr;
    });

    /* Add computed styles to stylesheet */
    for (let style of Array.from(opts.styles)) {
      /* Try getting locally first */
      if (_.isString(style)) {
        style = this.__getNamedStyle(style);
      }
      this.Stylesheet.push(style);
    }
  }

  __getNamedStyle(id) {
    let sourceFile = null;

    if (id.endsWith(".mss")) {
      console.log(`Checking path ${id} for stylesheet`);
      if (existsSync(id)) {
        sourceFile = id;
      }
    }

    if (sourceFile == null) {
      sourceFile = path.join(this.constructor.stylesheetDir, `${id}.mss`);
    }

    const { name } = path.parse(sourceFile);
    const data = readFileSync(sourceFile, "utf8");
    return { id: name, data, sourceFile };
  }

  toXml() {
    return cartoRenderer.render(this);
  }
}
MapStyle.initClass();

module.exports = { MapStyle };
