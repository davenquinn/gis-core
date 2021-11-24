/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const { getLeaflet } = require("./util");
const L = getLeaflet();

const d3 = null;

class DataLayer extends L.SVG {
  constructor() {
    this.setupProjection = this.setupProjection.bind(this);
    this.projectPoint = this.projectPoint.bind(this);
    this.onAdd = this.onAdd.bind(this);
    super();
    // Specify a particular d3
    // object to enable event propagation
    // if submodules are defined.
    this.d3 = this.options.d3 || require("d3");
    this.initialize({ padding: 0.1 });
  }

  setupProjection() {
    const f = this.projectPoint;
    this.projection = this.d3.geo.transform({
      point(x, y) {
        const point = f(x, y);
        return this.stream.point(point.x, point.y);
      },
    });

    return (this.path = this.d3.geo.path().projection(this.projection));
  }

  projectPoint(x, y) {
    return this._map.latLngToLayerPoint(new L.LatLng(y, x));
  }

  onAdd() {
    super.onAdd();
    this.setupProjection();
    this.svg = this.d3
      .select(this._container)
      .classed("data-layer", true)
      .classed("leaflet-zoom-hide", true);
    return this._map.on("viewreset", this.resetView);
  }

  resetView() {}
}

module.exports = DataLayer;
