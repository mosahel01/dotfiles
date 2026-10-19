import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root
    implicitHeight: layout.implicitHeight
    anchors.fill: parent

    // Background
    Rectangle {
        anchors.fill: parent
        color: Config.color_background
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 6

        BarLeft {}
        BarCenter {}
        BarRight {}
    }
}
