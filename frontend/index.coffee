remote = require 'remote'

el = document.querySelector '#main'
window.app = remote.require "app"

Map = require './map'

new Map el: el
