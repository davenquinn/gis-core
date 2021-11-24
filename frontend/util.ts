/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const getLeaflet = function () {
  if (typeof window !== "undefined" && window !== null) {
    return require("leaflet");
  }
  return require("leaflet-headless");
};

module.exports = { getLeaflet };
