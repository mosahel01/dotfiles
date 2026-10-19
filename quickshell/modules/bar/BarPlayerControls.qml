import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    spacing: Config.spacing_md
    Layout.alignment: Qt.AlignVCenter
    visible: Config.show_media_controls
              && (MediaPlayer.isAvailable || MediaPlayer.hasMetadata)

    component ControlButton: Rectangle {
        id: button
        required property string label
        signal triggered()

        property bool enabled: true
        property bool hovered: false
        property real sizeMultiplier: 1.0

        radius: Config.radius_sm
        color: hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.02)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        implicitWidth: (labelText.implicitWidth + Config.spacing_lg) * sizeMultiplier
        implicitHeight: (Config.bar_height - Config.spacing_lg) * sizeMultiplier
        opacity: enabled ? 1 : 0.4

        Text {
            id: labelText
            anchors.centerIn: parent
            text: button.label
            color: Config.color_foreground
            font.pointSize: Config.font_xs
            font.family: root.iconFont
            font.weight: 600
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled

            onClicked: button.triggered()
            onEntered: {
                cursorShape = Qt.PointingHandCursor
                button.hovered = true
            }
            onExited: button.hovered = false
            onCanceled: button.hovered = false
        }
    }

    property string iconFont: "Symbols Nerd Font Mono"

    ControlButton {
        label: "\udb81\udcae"
        enabled: MediaPlayer.hasMetadata
        onTriggered: MediaPlayer.previous()
    }

    ControlButton {
        label: MediaPlayer.isPlaying ? "\uf04c" : "\uf04b"
        enabled: MediaPlayer.isAvailable
        sizeMultiplier: 1.25
        onTriggered: MediaPlayer.playPause()
    }

    ControlButton {
        label: "\udb81\udcad"
        enabled: MediaPlayer.hasMetadata
        onTriggered: MediaPlayer.next()
    }
}
