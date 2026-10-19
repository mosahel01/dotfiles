import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    spacing: Config.spacing_lg
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.fillWidth: true
    visible: (Config.show_media_track_info || Config.show_media_controls)
             && (MediaPlayer.isAvailable || MediaPlayer.hasMetadata)

    BarTrackInfo {
        Layout.fillWidth: true
    }
}
