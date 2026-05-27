import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string valueDownloadDir: cfg.downloadDir ?? defaults.downloadDir ?? ""
  property string valueSearchQuery: cfg.searchQuery ?? defaults.searchQuery ?? ""
  property string valueApiKey: cfg.apiKey ?? defaults.apiKey ?? ""
  property string valuePurity: normalizePurity(cfg.purity ?? defaults.purity ?? "100")
  property var purityOptions: [
    { "key": "100", "name": pluginApi?.tr("settings.purity.sfw") },
    { "key": "110", "name": pluginApi?.tr("settings.purity.sketchy") },
    { "key": "111", "name": pluginApi?.tr("settings.purity.all") }
  ]

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.downloadDir.label")
      description: pluginApi?.tr("settings.downloadDir.desc")
      placeholderText: pluginApi?.tr("settings.downloadDir.placeholder")
      text: root.valueDownloadDir
      onTextChanged: root.valueDownloadDir = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.searchQuery.label")
      description: pluginApi?.tr("settings.searchQuery.desc")
      placeholderText: pluginApi?.tr("settings.searchQuery.placeholder")
      text: root.valueSearchQuery
      onTextChanged: root.valueSearchQuery = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.apiKey.label")
      description: pluginApi?.tr("settings.apiKey.desc")
      placeholderText: pluginApi?.tr("settings.apiKey.placeholder")
      text: root.valueApiKey
      onTextChanged: root.valueApiKey = text
    }

    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.purity.label")
      description: pluginApi?.tr("settings.purity.desc")
      model: root.purityOptions
      currentKey: root.valuePurity
      onSelected: key => root.valuePurity = key
    }
  }

  function normalizePurity(value) {
    var purity = String(value || "100");
    return purity === "100" || purity === "110" || purity === "111" ? purity : "100";
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Wallhaven", "Cannot save settings: pluginApi is null");
      return;
    }

    var downloadDir = root.valueDownloadDir.trim();
    pluginApi.pluginSettings.downloadDir = downloadDir !== "" ? downloadDir : (defaults.downloadDir ?? "~/Pictures/Wallpapers");
    pluginApi.pluginSettings.searchQuery = root.valueSearchQuery;
    pluginApi.pluginSettings.apiKey = root.valueApiKey.trim();
    pluginApi.pluginSettings.purity = normalizePurity(root.valuePurity);
    pluginApi.saveSettings();

    Logger.d("Wallhaven", "Settings saved successfully");
  }
}
