import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property bool downloadBusy: false
  property string pendingDownloadDest: ""

  Process {
    id: downloadProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      root.downloadBusy = false;
      var dest = root.pendingDownloadDest;
      var errorText = String(downloadProcess.stderr.text || "").trim();
      root.pendingDownloadDest = "";
      root.downloadFinished(exitCode, dest, errorText);
    }
  }

  IpcHandler {
    target: "plugin:wallhaven"
    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function (screen) {
          pluginApi.togglePanel(screen);
        });
      }
    }
  }

  function setting(key, fallback) {
    if (cfg[key] !== undefined && cfg[key] !== null && cfg[key] !== "") {
      return cfg[key];
    }
    if (defaults[key] !== undefined && defaults[key] !== null && defaults[key] !== "") {
      return defaults[key];
    }
    return fallback;
  }

  function expandPath(path) {
    var expanded = String(path || "");
    if (expanded === "~") {
      return Quickshell.env("HOME") || expanded;
    }
    if (expanded.indexOf("~/") === 0) {
      return (Quickshell.env("HOME") || "~") + "/" + expanded.substring(2);
    }
    return expanded;
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
  }

  function downloadWallpaper(url, id, ext) {
    if (downloadBusy) {
      ToastService.showError(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.busy"));
      return;
    }

    if (!url || !id) {
      ToastService.showError(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.downloadError"));
      return;
    }

    var dir = expandPath(setting("downloadDir", "~/Pictures/Wallpapers"));
    var cleanExt = ext === ".png" || ext === ".jpg" || ext === ".jpeg" || ext === ".webp" ? ext : ".jpg";
    var filename = "wallhaven-" + id + cleanExt;
    var dest = dir + "/" + filename;

    Logger.i("Wallhaven", "Downloading to: " + dest);

    downloadBusy = true;
    pendingDownloadDest = dest;
    downloadProcess.exec({
                           "command": [
                             "sh",
                             "-c",
                             "mkdir -p " + shellQuote(dir) + " && (curl -fL -sS -o " + shellQuote(dest) + " " + shellQuote(url) + " || wget -q -O " + shellQuote(dest) + " " + shellQuote(url) + ")"
                           ]
                         });
  }

  function downloadFinished(code, dest, errorText) {
    if (code === 0) {
      ToastService.showNotice(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.downloaded", { "path": dest }))
    } else {
      Logger.e("Wallhaven", "Download failed: " + (errorText || ("exit " + code)));
      ToastService.showError(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.downloadError"))
    }
  }
}
