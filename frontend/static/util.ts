const fs = require("fs");

module.exports.fileExists = function (fp) {
  try {
    return fs.statSync(fp).isFile();
  } catch (err) {
    return false;
  }
};
