import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Config.bar_height
    Layout.rightMargin: Config.hyprland_gap

    RowLayout {
        anchors.verticalCenter: root.verticalCenter
        anchors.right: root.right

        spacing: Config.spacing_5xl

        BarNotifications {}
        BarPlayerControls {}
        BarTray {}
        // BarBattery {}
        BarTime {}
    }
}
