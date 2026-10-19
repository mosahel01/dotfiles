import QtQuick
import QtQuick.Controls
import qs.services
import qs.config

Button {
    id: root

    visible: NotificationsManager.count > 0

    text: "Dismiss " + NotificationsManager.count + " notification" + (NotificationsManager.count > 1 ? "s" : "")
    leftPadding: 10
    rightPadding: 10

    background: Rectangle {
        color: root.hovered ? Config.color_foreground : Config.color_background
        border.color: Config.color_border
        border.width: 1
        radius: Config.radius
    }

    contentItem: Text {
        text: root.text
        color: root.hovered ? Config.color_background : Config.color_foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 14
    }

    onClicked: {
        NotificationsManager.dismissAll();
    }
}
