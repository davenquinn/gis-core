# GIS Core

`gis-core` is a NodeJS mapping UI module that is designed
to bring the best of web-mapping tools to desktop GIS.

The module allows some of the best features of desktop GIS
to be used in a web mapping framework:

- arbitrary projections
- direct access to databases
- virtually any raster/vector format (based on GDAL)

These can be styled using `mapnik` and CartoCSS,
and displayed using
javascript (which can then be extended with editable layers
or visualizations in a manner akin to web maps).
This approach attempts to bridge the gap between ArcGIS/QGIS
and web mapping, where more control and customization is
required.

Maps are configurable using simple file-based configuration
and standard mapnik styles. The frontend is a minimally modified
`leaflet` map. Stylesheet reloading (in progress)
provides a quick way to iterate on map styles. The module
can be used standalone or as a component of a larger application.

This is designed to function within a GUI environment
with access to native node modules, such as `electron` or
`node-webkit`. The module depends on the `mapnik` framework
(via the `node-mapnik` bindings)

## TODO

- Stylesheet/datasource reloading
- Direct CartoCSS support
- Support for read/write of mbtiles
