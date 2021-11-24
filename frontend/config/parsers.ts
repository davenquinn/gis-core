/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const parseYaml = function (text) {
  const yaml = require("js-yaml");
  return yaml.safeLoad(text);
};

module.exports = {
  yaml: parseYaml,
  yml: parseYaml,
  json: JSON.parse,
};
