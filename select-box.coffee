L = require "leaflet"

class BoxSelect extends L.Map.BoxZoom
  _onMouseUp: (e)->
    return false if (e.which isnt 1) and (e.button isnt 1)
    @_finish()
    return unless @_moved
    s = @_map.containerPointToLatLng @_startPoint
    e = @_map.containerPointToLatLng @_point

    bounds = new L.LatLngBounds s,e
    @_map.fire 'box-selected', bounds: bounds

module.exports = BoxSelect
