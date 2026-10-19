import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick.Layouts
import qs.config

RowLayout {
    spacing: Config.spacing_lg

    Repeater {
        model: SystemTray.items

        IconImage {
            id: iconImage
            required property SystemTrayItem modelData
            source: modelData.icon
            implicitSize: 16

            QsMenuAnchor {
                id: menuAnchor
                anchor.item: iconImage
                anchor.gravity: Edges.Bottom | Edges.Left
                menu: iconImage.modelData.menu
            }

            MouseArea {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent
                onClicked: mouse => {
                    if (mouse.button == Qt.LeftButton) {
                        iconImage.modelData.activate();
                    } else if (mouse.button == Qt.RightButton) {
                        menuAnchor.open();
                    }
                }
            }
        }
    }
}
