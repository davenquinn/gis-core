/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const mapnik = require("mapnik");
const mapnikPool = require("mapnik-pool");
const { GridLayer } = require("leaflet");

const pooledMapnik = mapnikPool(mapnik);
mapnik.register_default_fonts();
mapnik.register_default_input_plugins();
mapnik.register_system_fonts();

const coordString = (coords) =>
  `x: ${coords.x}, y: ${coords.y}, zoom: ${coords.z}`;

class MapnikLayer extends GridLayer {
  constructor(id, xml, options) {
    this.id = id;
    super();
    this.options.updateWhenIdle = true;
    if (this.options.verbose == null) {
      this.options.verbose = false;
    }
    this.initialize(options);

    this.pool = pooledMapnik.fromString(xml, { size: this.options.tileSize });
    this.log("Created map pool");
  }

  log() {
    if (this.options.verbose) {
      return console.log(`(${this.constructor.name})`, ...arguments);
    }
  }

  createTile(coords, cb) {
    const cs = coordString(coords);
    console.log(cs);

    const r = window.devicePixelRatio || 1;
    const scaledSize = this.options.tileSize * r;

    const tile = new Image();
    tile.width = tile.height = scaledSize;

    const { crs } = this._map.options;
    const { bounds } = crs.projection;
    const sz = this.options.tileSize / crs.scale(coords.z);

    const ll = {
      x: bounds.min.x + coords.x * sz,
      y: bounds.max.y - (coords.y + 1) * sz,
    };
    const ur = {
      x: bounds.min.x + (coords.x + 1) * sz,
      y: bounds.max.y - coords.y * sz,
    };
    const box = [ll.x, ll.y, ur.x, ur.y];

    const { pool } = this;

    pool.acquire((e, map) => {
      console.log("Acquired map from pool");
      if (e) {
        if (map != null) {
          pool.release(map);
        }
        cb(e);
        return;
      }
      if (!this._zooming && this._map.getZoom() !== coords.z) {
        this.log("Tile at wrong zoom level");
        pool.release(map);
        cb(Error("Tile at wrong zoom level"));
        return;
      }

      map.width = map.height = scaledSize;
      const im = new mapnik.Image(map.width, map.height);

      map.extent = box;

      const mapScale = map.scale();
      const scaleDenominator = map.scaleDenominator();
      console.log(mapScale);

      const variables = { mapScale, scaleDenominator };

      return map.render(im, { scale: r, variables }, (err, im) => {
        if (err) {
          throw err;
        }
        const i_ = im.encodeSync("png");
        const blob = new Blob([i_], { type: "image/png" });
        const url = URL.createObjectURL(blob);

        tile.src = url;
        tile.onload = () => {
          return URL.revokeObjectURL(url);
        };
        console.log("Releasing map back to pool");
        pool.release(map);
        return cb(null, tile);
      });
    });

    return tile;
  }

  onAdd(map) {
    this.log("Adding to ", map);
    if (this.options.tileSize == null) {
      this.options.tileSize = map.config.tileSize || 256;
    }

    // We want to be able to check if we are currently
    // zooming
    this._zooming = false;
    map.on("zoomstart", () => {
      return (this._zooming = true);
    });
    map.on("zoomend", () => {
      return (this._zooming = false);
    });

    return super.onAdd(map);
  }
}

module.exports = MapnikLayer;
