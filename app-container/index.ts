/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const { app, BrowserWindow } = require("electron");
const mn = require("minimist");

const args = mn(process.argv.slice(2));

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
global.mainWindow = null;

// Quit when all windows are closed.
app.on("window-all-closed", () => app.quit());

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
const startApp = function (url) {
  // Create the browser window.
  let mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
  });
  // and load the index.html of the app.
  mainWindow.loadURL(url);
  // Open the DevTools.
  //mainWindow.openDevTools();
  // Emitted when the window is closed.
  return mainWindow.on(
    "closed",
    () =>
      // Dereference the window object, usually you would store windows
      // in an array if your app supports multi windows, this is the time
      // when you should delete the corresponding element.
      (mainWindow = null)
  );
};

// Load the application window after the server is
// set up

// Right now, the environment variable "NODE_MAP_CONFIG"
// should point to the config file
app.configFile = args._[0];
app.on("ready", () => startApp(`file://${__dirname}/main.html`));
