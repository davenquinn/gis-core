/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const mapnik = require("mapnik");
const path = require("path");
const fs = require("fs");
const d3 = require("d3");
const { select, selection } = require("d3-selection");
require("d3-selection-multi");
const { fileExists } = require("./util");
mapnik.register_default_fonts();
mapnik.register_default_input_plugins();
mapnik.register_system_fonts();
const { bboxPolygon } = require("turf");
const _ = require("underscore");
const { Renderer } = require("carto");

const Promise = require("bluebird");
// load map config
const loadCfg = require("../config/map");

const boundsFromEnvelope = function (bbox) {
  if (bbox.geometry != null) {
    bbox = bbox.geometry;
  }
  if (bbox.coordinates != null) {
    let c = bbox.coordinates;
    if (bbox.type === "Polygon") {
      c = c[0];
    }
    return [c[0][0], c[0][1], c[2][0], c[2][1]];
  }
  return bbox;
};

const ECANNOTRENDER = "Can't render – layers could not be loaded.";

const guardSelection = function (el) {
  if (el.node != null) {
    el = el.node();
  }
  return select(el);
};

class StaticMap {
  constructor(size, bbox, style, extraCfg) {
    /*
    Can use bounding box or tuple of urx,ury,llx,lly
    */
    let mapData;
    this.projection = this.projection.bind(this);
    this.geoDimensions = this.geoDimensions.bind(this);
    this.createFeatures = this.createFeatures.bind(this);
    this.transform = this.transform.bind(this);
    this.inverseTransform = this.inverseTransform.bind(this);
    this.geoPath = this.geoPath.bind(this);
    this.__pathGenerator = this.__pathGenerator.bind(this);
    this.path = this.path.bind(this);
    this.scaleComponent = this.scaleComponent.bind(this);
    this.waitForImages = this.waitForImages.bind(this);
    this.create = this.create.bind(this);
    this.size = size;
    this.style = style;
    if (extraCfg == null) {
      extraCfg = {};
    }
    this.imageScale = extraCfg.scale || 2;
    this.scaleMap = extraCfg.scaleMap || false;
    const MPATH = process.env.MAPNIK_STYLES;
    if (this.style == null) {
      this.style = "ortho";
    }
    if (extraCfg.layers == null) {
      extraCfg.layers = process.env.MAPNIK_LAYERS;
    }

    //# Paths to extra CartoCSS stylesheets
    if (extraCfg.styles == null) {
      extraCfg.styles = [];
    }

    if (_.isString(this.style)) {
      const cfg = path.join(MPATH, `${this.style}.yaml`);
      mapData = loadCfg(cfg, extraCfg);
    } else {
      // We have provided a full mml object
      const renderer = new Renderer();

      mapData = { name: "map-style", xml: renderer.render(this.style) };
    }

    let sz = this.size.width;
    if (this.size.height > sz) {
      sz = this.size.height;
    }
    const maxSize = sz * this.imageScale * 2;
    this.maxSize = this.maxSize;

    this._map = new mapnik.Map(
      this.size.width * this.imageScale,
      this.size.height * this.imageScale
    );
    this.canRender = false;
    try {
      this._map.fromStringSync(mapData.xml);
      this.canRender = true;
    } catch (err) {
      console.error(err);
      // Construct a bare-bones map without layers
      const match = /srs="[^"]+"/.exec(mapData.xml);
      const srs = match[0];
      const ms = `<Map ${srs} />`;
      this._map.fromStringSync(ms);
    }
    if (bbox == null) {
      bbox = [200, 200, -200, -200];
    }
    this.setBounds(bbox);
    this.__render = (opts) => {
      return new Promise((res, rej) => {
        const w = this.size.width * this.imageScale;
        const h = this.size.height * this.imageScale;
        console.log(w, h);
        if (this.scaleMap) {
          if (opts.scale == null) {
            opts.scale = this.imageScale;
          }
        }
        const im = new mapnik.Image(w, h);
        console.log("Starting to render map");
        return this._map.render(im, opts, function (e, m) {
          console.log(opts);
          if (e != null) {
            rej(e);
          }
          console.log("Done rendering map");
          return res(m);
        });
      });
    };
  }

  setBounds(bbox) {
    //# Can use an envelope feature or geometry
    const bounds = boundsFromEnvelope(bbox);
    // Update bounding box size according to map zoom settings
    this._map.extent = bounds;
    this.extent = this._map.extent;
    // Scale is equal for both x and y obviously
    this.scale = this.size.width / (this.extent[2] - this.extent[0]);
    // Version of scale that matches mapnik. The old one
    // is deprecated and will soon be removed
    this.mapScale = 1 / (this.scale * this.imageScale);
    return (this._proj = new mapnik.Projection(this._map.srs));
  }

  boundingPolygon() {
    return bboxPolygon(this._map.extent);
  }

  projection([x, y, z]) {
    const v = this._proj.forward([x, y]);
    return this.transform(v);
  }

  geoDimensions() {
    // Get the width and height in map unit
    const e = this.extent;
    return { width: e[2] - e[0], height: e[3] - e[1] };
  }

  createFeatures(classname, opts) {
    // Basic method to create a selection of features
    // that can be styled using css.
    if (opts == null) {
      opts = {};
    }
    if (opts.geographic == null) {
      opts.geographic = true;
    }
    const pathGenerator = opts.geographic ? this.geoPath : this.path;
    const container = this.dataArea;

    const fn = {};
    fn.data = function (data) {
      // Returns selection
      const el_ = container.append("g").attrs({ class: classname });
      const sel = el_.selectAll(`path.${classname}`).data(data);

      return sel.enter().append("path").attrs({
        d: pathGenerator,
        class: classname,
      });
    };

    return fn;
  }

  transform(d) {
    return [
      (d[0] - this.extent[0]) * this.scale,
      (this.extent[3] - d[1]) * this.scale,
    ];
  }

  inverseTransform(d) {
    return [
      d[0] / this.scale + this.extent[0],
      this.extent[3] - d[1] / this.scale,
    ];
  }

  __setupGeoPath() {
    // Must be in lat/lon to use geo path
    const _proj = this.projection;
    const trans = d3.geoTransform({
      point(x, y) {
        const v = _proj([x, y]);
        return this.stream.point(v[0], v[1]);
      },
    });
    return d3.geoPath().projection(trans);
  }

  geoPath(d) {
    if (this._geoPath == null) {
      this._geoPath = this.__setupGeoPath();
    }
    return this._geoPath(d);
  }

  __pathGenerator() {
    // Must be in lat/lon to use geo path
    const _proj = this.transform;
    const trans = d3.geoTransform({
      point(x, y) {
        const v = _proj([x, y]);
        return this.stream.point(v[0], v[1]);
      },
    });
    return d3.geoPath().projection(trans);
  }

  path(d) {
    // A path in projected coordinates
    if (this._path == null) {
      this._path = this.__pathGenerator();
    }
    return this._path(d);
  }

  scaleComponent(opts) {
    // A component for a d3 svg scale
    const buildScale = require("./scale");
    const _map = this;
    return (el) => buildScale(el, _map, opts);
  }

  render(fn, opts) {
    // Render a cacheable map to a filename
    // Only render the map if the file doesn't exist
    if (opts == null) {
      opts = {};
    }
    const overwrite = opts.overwrite || true;
    if (!fileExists(fn) || overwrite) {
      const im = this._map.renderSync({
        format: "png",
        scale: this.imageScale,
      });
      const dir = path.dirname(fn);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir);
      }
      fs.writeFileSync(fn, im);
    }
    this.filename = fn;
    return fn;
  }

  renderAsync(fn, variables) {
    // Render a cacheable map to a filename
    // Only render the map if the file doesn't exist
    if (variables == null) {
      variables = {};
    }
    const { writeFile } = Promise.promisify(fs);

    variables.lowerBound = 0;
    variables.upperBound = 300;

    if (fileExists(fn)) {
      this.filename = Promise.resolve(fn);
    }
    return (this.filename = this.__render({ format: "png", variables })
      .tap(function () {
        const dir = path.dirname(fn);
        if (!fs.existsSync(dir)) {
          return fs.mkdirSync(dir);
        }
      })
      .then(function (im) {
        writeFile(fn, im);
        return fn;
      }));
  }

  renderToObjectUrl(variables) {
    if (variables == null) {
      variables = {};
    }
    return (this.filename = this.__render({ format: "png", variables })
      .then(
        (im) =>
          new Promise(function (res, rej) {
            console.log("Encoded");
            return im.encode("png", { max_size: 100000 }, (e, c) => res(c));
          })
      )
      .then(function (im) {
        console.log("Creating blob");
        const blob = new Blob([Buffer.from(im)], { type: "image/png" });
        console.log("Creating object URL");
        return URL.createObjectURL(blob);
      }));
  }

  waitForImages() {
    return new Promise((res) => {
      return this.image.on("load", res);
    });
  }

  create(el, opts) {
    /*
     * Returns a promise of an element
     *
     * Can be passed a d3 selection or a html node
     */
    if (opts == null) {
      opts = {};
    }
    console.log("Beginning to render map");
    el = guardSelection(el);
    const { width, height } = this.size;
    el.attrs({ width, height });
    this.el = el;

    if (opts.variables == null) {
      opts.variables = {};
    }
    if (this.filename == null) {
      this.renderToObjectUrl(opts.variables);
    }

    const p = this.filename.then((filename) => {
      const defs = el.append("defs");

      const cp = "map-bounds";
      defs.append("rect").attrs(this.size).attrs({ id: cp });

      defs
        .append("clipPath")
        .attr("id", "mapClip")
        .append("use")
        .attr("xlink:href", `#${cp}`);

      this.image = el
        .append("image")
        .attr("xlink:href", filename)
        .attrs(this.size);

      this.dataArea = el.append("g").attrs({
        class: "data-area",
        "clip-path": "url(#mapClip)",
      });

      this.overlay = el.append("g").attrs({
        class: "overlay",
        "clip-path": "url(#mapClip)",
      });

      if (opts.scale == null) {
        return this;
      }
      if (!opts.scale) {
        return this;
      }

      if (typeof opts.scale === "boolean") {
        opts.scale = {};
      }

      if (opts.scale.width == null) {
        opts.scale.width = this.size.width / 3;
      }
      opts.scale.standalone = false;
      this.overlay
        .append("g")
        .attr("class", "scale")
        .attr("transform", `translate(10 ${this.size.height - 10})`)
        .call(this.scaleComponent(opts.scale));
      return this;
    });
    return p;
  }
  //p.then @waitForImages

  async createTiled(el) {
    let args, maxX, maxY, minX, minY, topLeftBBox;
    el = guardSelection(el);
    const { width, height } = this.size;
    console.log(this.size);
    el.styles({ width, height, position: "relative", overflow: "hidden" });
    const tileSize = 1024;
    //# Internal spherical mercator projection
    const SphericalMercator = require("sphericalmercator");
    const merc = new SphericalMercator({
      size: tileSize,
    });
    const scale = 2;
    const pxWidth = width * scale;
    const nTiles = pxWidth / tileSize;

    let tspan = 0;
    let z = 0;
    while (tspan < nTiles) {
      z += 1;
      args = [z, false, "900913"];
      ({ minX, maxX, minY, maxY } = merc.xyz(this.extent, ...args));
      topLeftBBox = merc.bbox(minX, minY, ...args);
      tspan = maxX - minX;
      console.log(tspan, z);
    }
    console.log(`Zoom level ${z}`);

    // Offset in map coordinate view
    const offset = [
      topLeftBBox[0] - this.extent[0],
      this.extent[3] - topLeftBBox[3],
    ];
    const cfg = {
      xml: this._map.toXML(),
      pathname: this.style.path || "style.xml",
      tileSize,
      metatile: 4,
      scale: 4 * scale,
    };
    const p = await new Promise(function (resolve, reject) {
      const M = require("tilestrata-mapnik");
      const renderer = M(cfg);
      return renderer.init(null, function (e, backend) {
        if (e != null) {
          reject(e);
        }
        return resolve(renderer);
      });
    });

    const renderer = await p;

    const { transform } = this;
    return __range__(minX, maxX, true).map((x, i) =>
      __range__(minY, maxY, true).map(function (y, j) {
        const bbox = merc.bbox(x, y, ...args);
        const px = transform([bbox[0], bbox[3]]);
        const pxA = transform([bbox[2], bbox[1]]);
        const sa = pxA[0] - px[0];

        return renderer.serve(null, { z, y, x }, function (err, buffer) {
          const blob = new Blob([buffer], { type: "image/png" });
          const uri = URL.createObjectURL(blob);
          console.log(px, pxA);
          const xpos = px[0]; //-128*i
          const ypos = px[1]; //-128*j
          const im = el
            .append("img")
            .attr("src", uri)
            .styles({
              position: "absolute",
              transform: `translate(${xpos}px,${ypos}px)`,
              width: sa,
              height: sa,
              top: 0,
              left: 0,
            })
            .on("load", () => URL.revokeObjectURL(uri));

          return console.log(im.node());
        });
      })
    );
  }
}

module.exports = StaticMap;

function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}
