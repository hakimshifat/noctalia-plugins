import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 500 * Style.uiScaleRatio
  property real contentPreferredHeight: 600 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  anchors.fill: parent

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  
  property string query: cfg.searchQuery ?? defaults.searchQuery ?? ""
  property string apiKey: cfg.apiKey ?? defaults.apiKey ?? ""
  property string purity: normalizePurity(cfg.purity ?? defaults.purity ?? "100")
  
  property int currentPage: 1
  property bool isLoading: false
  property string statusKey: ""

  ListModel { id: wallpaperModel }

  function normalizePurity(value) {
    var normalized = String(value || "100");
    return normalized === "100" || normalized === "110" || normalized === "111" ? normalized : "100";
  }

  function purityRequiresApi(value) {
    return String(value).charAt(2) === "1";
  }

  function extensionForFileType(fileType) {
    if (fileType === "image/png") return ".png";
    if (fileType === "image/webp") return ".webp";
    return ".jpg";
  }

  function fetchWallpapers(page) {
    if (isLoading) return;

    if (page === 1) {
      wallpaperModel.clear();
    }

    if (purityRequiresApi(purity) && apiKey.trim() === "") {
      statusKey = "panel.apiKeyRequired";
      ToastService.showError(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.apiKeyRequired"));
      return;
    }

    isLoading = true;
    statusKey = "panel.loading";

    var url = "https://wallhaven.cc/api/v1/search?page=" + page + "&purity=" + purity;
    if (query !== "") url += "&q=" + encodeURIComponent(query);
    if (apiKey !== "") url += "&apikey=" + encodeURIComponent(apiKey);

    var req = new XMLHttpRequest();
    req.open("GET", url);
    req.onreadystatechange = function() {
      if (req.readyState === XMLHttpRequest.DONE) {
        isLoading = false;
        if (req.status === 200) {
          try {
            var res = JSON.parse(req.responseText);
            var data = res.data || [];
            Logger.i("Wallhaven", "Loaded " + data.length + " wallpapers");
            for (var i = 0; i < data.length; i++) {
              var item = data[i];
              wallpaperModel.append({
                itemId: item.id,
                thumbUrl: item.thumbs && item.thumbs.small ? item.thumbs.small : "",
                fullUrl: item.path || "",
                resolution: item.resolution || "",
                fileType: item.file_type || "image/jpeg"
              });
            }
            statusKey = wallpaperModel.count === 0 ? "panel.empty" : "";
          } catch (error) {
            Logger.e("Wallhaven", "Parse Error: " + error);
            statusKey = "panel.loadError";
            ToastService.showError(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.loadError"));
          }
        } else {
          Logger.e("Wallhaven", "API Error: " + req.status);
          statusKey = "panel.loadError";
          ToastService.showError(pluginApi?.tr("plugin.name"), pluginApi?.tr("panel.loadError"));
        }
      }
    }
    req.send();
  }

  Component.onCompleted: {
    fetchWallpapers(1);
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "image-outline"
          pointSize: Style.fontSizeL
          color: Color.mPrimary
        }

        NText {
          Layout.fillWidth: true
          text: pluginApi?.tr("panel.title")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        NIconButton {
          icon: "refresh"
          tooltipText: pluginApi?.tr("panel.refresh")
          enabled: !root.isLoading
          onClicked: {
            root.currentPage = 1;
            fetchWallpapers(1);
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        
        NTextInput {
          id: searchInput
          Layout.fillWidth: true
          text: root.query
          onTextChanged: root.query = text
          placeholderText: pluginApi?.tr("settings.searchQuery.placeholder")
        }
        
        NButton {
          text: pluginApi?.tr("panel.refresh")
          enabled: !root.isLoading
          onClicked: {
            root.currentPage = 1;
            fetchWallpapers(1);
          }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        GridView {
          id: grid
          anchors.fill: parent
          clip: true
          cellWidth: Math.max(120 * Style.uiScaleRatio, width / 3)
          cellHeight: cellWidth * 0.75
          model: wallpaperModel

          delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            
            NBox {
              anchors.fill: parent
              anchors.margins: Style.marginS
              color: Color.mSurfaceVariant
              radius: Style.radiusS
              clip: true
              
              Image {
                id: img
                anchors.fill: parent
                source: model.thumbUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
              }

              NIcon {
                anchors.centerIn: parent
                icon: "photo"
                pointSize: Style.fontSizeXL
                color: Color.mOnSurfaceVariant
                visible: img.status !== Image.Ready
              }

              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 30 * Style.uiScaleRatio
                color: Qt.alpha(Color.mSurface, 0.82)
                
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.marginS
                  
                  NText {
                    Layout.fillWidth: true
                    text: model.resolution
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurface
                  }
                  
                  NIconButton {
                    icon: "download"
                    implicitWidth: 20 * Style.uiScaleRatio
                    implicitHeight: 20 * Style.uiScaleRatio
                    onClicked: {
                      if (pluginApi && pluginApi.mainInstance) {
                        pluginApi.mainInstance.downloadWallpaper(model.fullUrl, model.itemId, extensionForFileType(model.fileType));
                      }
                    }
                  }
                }
              }
            }
          }
        }

        NBox {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.marginXL, 320 * Style.uiScaleRatio)
          height: statusColumn.implicitHeight + Style.marginXL
          color: Color.mSurfaceVariant
          radius: Style.radiusM
          visible: wallpaperModel.count === 0 && (root.isLoading || root.statusKey !== "")

          ColumnLayout {
            id: statusColumn
            anchors.centerIn: parent
            width: parent.width - Style.marginXL
            spacing: Style.marginS

            NIcon {
              Layout.alignment: Qt.AlignHCenter
              icon: root.isLoading ? "loader-2" : "photo-off"
              pointSize: Style.fontSizeXL
              color: Color.mPrimary
            }

            NText {
              Layout.fillWidth: true
              text: root.statusKey !== "" ? pluginApi?.tr(root.statusKey) : ""
              pointSize: Style.fontSizeS
              color: Color.mOnSurface
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }
          }
        }
      }
      
      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        
        NButton {
          text: pluginApi?.tr("panel.loadMore")
          enabled: !root.isLoading && wallpaperModel.count > 0
          onClicked: {
            root.currentPage++;
            fetchWallpapers(root.currentPage);
          }
        }
      }
    }
  }
}
