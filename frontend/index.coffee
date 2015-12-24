remote = require 'remote'
Map = require './map'

el = document.querySelector '#main'
window.app = remote.require "app"

options = app.config.map
new Map el, options
