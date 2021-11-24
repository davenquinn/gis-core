/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let L;
try {
  const h =
    typeof window !== "undefined" && window !== null
      ? "leaflet"
      : "leaflet-headless";
  L = require(h);
} catch (e) {
  console.log("Couldn't load leaflet");
}
const parseConfig = require("./config");
const MapnikLayer = require("./mapnik-layer");
const TestLayer = require("./test-layer");
const setupProjection = require("./projection");

const defaultOptions = {
  tileSize: 256,
  zoom: 0,
  attributionControl: false,
  continuousWorld: true,
  debounceMoveend: true,
};

class Map extends L.Map {
  constructor(el, opts) {
    let k, v;
    this.addMapnikLayers = this.addMapnikLayers.bind(this);
    this.addLayerControl = this.addLayerControl.bind(this);
    this.addScalebar = this.addScalebar.bind(this);
    console.log(opts);
    let c = null;
    if (c == null) {
      c = opts.configFile;
    }
    if (c == null) {
      c = opts;
    }
    const cfg = parseConfig(c);
    // Keep mapnik layer configs separate from
    // other layers (this is probably temporary)
    const lyrs = {};
    for (let lyr of Array.from(cfg.layers)) {
      lyrs[lyr.name] = new MapnikLayer(lyr.name, lyr.xml, { verbose: true });
    }
    const options = {};
    options.mapnikLayers = lyrs;

    // Set options (values defined in code
    // take precedence).
    options.layers = [];
    for (k in cfg) {
      v = cfg[k];
      if (options[k] == null) {
        options[k] = v;
      }
    }

    if (options.projection != null) {
      const s = options.projection;
      const projection = setupProjection(s, {
        minResolution: options.resolution.min, // m/px
        maxResolution: options.resolution.max, // m/px
        bounds: options.bounds,
      });
      options.crs = projection;
    }

    for (k in defaultOptions) {
      v = defaultOptions[k];
      if (options[k] == null) {
        options[k] = v;
      }
    }

    super(el, options);
    this.addMapnikLayers(options.initLayer || null);
  }

  addMapnikLayers(name) {
    let lyr;
    const layers = this.options.mapnikLayers;
    if (name != null) {
      lyr = layers[name];
    }

    if (lyr == null) {
      // Add the first layer (arbitrarily)
      for (let k in layers) {
        const l = layers[k];
        lyr = l;
        break;
      }
    }

    console.log(this.options);
    console.log(lyr);
    return lyr.addTo(this);
  }

  addLayerControl(baseLayers, overlayLayers) {
    console.log(this.options);
    const lyrs = this.options.mapnikLayers;
    for (let k in baseLayers) {
      const v = baseLayers[k];
      lyrs[k] = v;
    }
    const ctl = new L.Control.Layers(lyrs, overlayLayers, {
      position: "topleft",
    });
    return ctl.addTo(this);
  }

  addScalebar() {
    const scale = new L.Control.Scale({
      maxWidth: 250,
      imperial: false,
    });
    return scale.addTo(this);
  }
}

module.exports = Map;
