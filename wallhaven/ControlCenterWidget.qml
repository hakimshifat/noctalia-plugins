import QtQuick
import Quickshell
import qs.Widgets
import qs.Commons

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null

  icon: "image-outline"
  tooltipText: pluginApi?.tr("widget.tooltip")
  
  onClicked: {
    if (pluginApi) pluginApi.togglePanel(screen, this)
  }
}
