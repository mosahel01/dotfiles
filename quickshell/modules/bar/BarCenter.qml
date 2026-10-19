import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Config.bar_height
    Layout.leftMargin: Config.hyprland_gap
    Layout.rightMargin: Config.hyprland_gap

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -Math.max(1, Config.spacing_base / 8)
            leftMargin: Config.spacing_lg
            rightMargin: Config.spacing_lg
        }

        BarMediaControls {
            Layout.fillWidth: true
        }
    }
}
