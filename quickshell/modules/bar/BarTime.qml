import QtQuick
import qs.services
import qs.config

Text {
    property color textColor: "white"
    text: FormattedTime.time
    font.weight: 600
    color: Config.color_foreground
    font.pointSize: Config.font_xs
}
