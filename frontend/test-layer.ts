/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const { getLeaflet } = require("./util");
const L = getLeaflet();

const coordString = (coords) =>
  `x: ${coords.x}, y: ${coords.y}, zoom: ${coords.z}`;

class TestLayer extends L.GridLayer {
  constructor(options) {
    this.log = this.log.bind(this);
    this.createTile = this.createTile.bind(this);
    super();
    this.options.updateWhenIdle = true;
    this.options.verbose = true;
    this.initialize(options);
  }

  log() {
    if (this.options.verbose) {
      return console.log(`(${this.constructor.name})`, ...arguments);
    }
  }

  createTile(coords) {
    const cs = coordString(coords);
    const tile = document.createElement("canvas");
    const ctx = tile.getContext("2d");
    tile.width = tile.height = 256;
    ctx.fillStyle = "white";
    ctx.fillRect(0, 0, 255, 255);
    ctx.fillStyle = "black";
    ctx.fillText(cs, 20, 20);
    ctx.strokeStyle = "red";
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(255, 0);
    ctx.lineTo(255, 255);
    ctx.lineTo(0, 255);
    ctx.closePath();
    ctx.stroke();
    this.log("Rendering", cs);
    return tile;
  }

  onAdd(map) {
    this.log("Adding to ", map);
    if (this.options.tileSize == null) {
      this.options.tileSize = map.config.tileSize || 256;
    }
    return super.onAdd(map);
  }
}

module.exports = TestLayer;
