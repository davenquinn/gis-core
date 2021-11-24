const { remote } = require("electron");
const gis = require("../frontend");
const L = require("leaflet");

const el = document.querySelector("#main");

const map = new gis.Map(el, {
  configFile: remote.app.configFile,
  zoom: 2,
  boxZoom: false,
  continuousWorld: true,
  debounceMoveend: true,
});

map.addLayerControl();

const scale = L.control.scale({
  maxWidth: 250,
  imperial: false,
});
scale.addTo(map);
