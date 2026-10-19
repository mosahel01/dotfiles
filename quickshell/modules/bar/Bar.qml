import Quickshell
import Quickshell.Wayland

import qs.config

Scope {
    id: root
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: Config.color_transparent
            implicitHeight: barContent.implicitHeight

            anchors {
                bottom: true
                left: true
                right: true
            }

            BarContent {
                id: barContent
            }
        }
    }
}
