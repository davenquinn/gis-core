remote = require 'remote'
Map = require './map'

el = document.querySelector '#main'
window.app = remote.require "app"

new Map el: el
