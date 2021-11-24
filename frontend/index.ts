const mapnik = require("mapnik");
const mapnikPool = require("mapnik-pool");

const pooledMapnik = mapnikPool(mapnik);
mapnik.register_default_fonts();
mapnik.register_default_input_plugins();

const { getLeaflet } = require("./util");
const L = getLeaflet();

module.exports = {
  Map: require("./map"),
  MapnikLayer: require("./mapnik-layer"),
  Leaflet: L,
  StaticMap: require("./static"),
  ...require("./map-style"),
  ...require("./raster-colorizer"),
};
