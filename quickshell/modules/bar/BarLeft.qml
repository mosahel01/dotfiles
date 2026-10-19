import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Config.bar_height
    Layout.leftMargin: Config.hyprland_gap

    RowLayout {
        anchors.verticalCenter: root.verticalCenter
        anchors.left: root.left

        spacing: Config.spacing_2xl

        BarWorkspaces {}
        BarSystemStats {
            visible: Config.show_system_stats
        }
    }
}
