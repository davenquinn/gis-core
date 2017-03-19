fs = require 'fs'

module.exports.fileExists = (fp)->
  try
    return fs.statSync(fp).isFile()
  catch err
    return false

