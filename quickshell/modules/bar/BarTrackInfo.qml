import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    readonly property string trackTitle: MediaPlayer.displayText || ""
    readonly property string timeString: MediaPlayer.timeDisplay || ""
    readonly property bool showTime: Config.show_media_time && timeString.length > 0
    visible: Config.show_media_track_info

    Layout.fillWidth: true
    Layout.preferredWidth: 280
    Layout.maximumWidth: 420
    spacing: root.showTime ? Config.spacing_xs : 0
    opacity: MediaPlayer.hasMetadata ? 1 : 0.6
    Layout.alignment: Qt.AlignHCenter

    Item {
        Layout.preferredWidth: root.showTime ? timeText.width : 0
        Layout.minimumWidth: Layout.preferredWidth
        Layout.maximumWidth: Layout.preferredWidth
    }

    Text {
        id: trackText
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: Config.color_foreground
        font.pointSize: Config.font_xs
        font.weight: 600
        text: root.trackTitle
    }

    Text {
        id: timeText
        visible: root.showTime
        color: Config.color_foreground
        font.pointSize: Config.font_xs
        font.weight: 600
        text: "(" + root.timeString + ")"
    }
}
