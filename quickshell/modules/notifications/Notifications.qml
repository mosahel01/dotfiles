import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notificationsWindow
            required property var modelData

            property bool matchesFocusedMonitor: Hyprland.focusedMonitor && modelData?.name === Hyprland.focusedMonitor.name
            property bool isFallbackMonitor: !Hyprland.focusedMonitor && modelData === Quickshell.screens[0]
            readonly property bool shouldShow: NotificationsManager.count > 0 && (matchesFocusedMonitor || isFallbackMonitor)

            visible: shouldShow
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: `quickshell:notificationsWindow:${modelData?.name ?? "unknown"}`
            aboveWindows: true
            color: Config.color_transparent
            implicitHeight: notificationsLoader.item ? notificationsLoader.item.implicitHeight : 0
            implicitWidth: notificationsLoader.item ? notificationsLoader.item.implicitWidth : 0
            screen: modelData

            anchors {
                top: true
                right: true
            }

            Loader {
                id: notificationsLoader
                anchors.fill: parent
                active: notificationsWindow.visible
                sourceComponent: notificationsContent
            }

            Component {
                id: notificationsContent

                ScrollView {
                    id: scrollview
                    implicitWidth: notificationsColumn.implicitWidth
                    implicitHeight: Math.min(notificationsColumn.implicitHeight, Screen.height - Config.bar_height)

                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: notificationsColumn
                        spacing: Config.spacing_base

                        Repeater {
                            model: NotificationsManager.items

                            Rectangle {
                                id: notification

                                required property Notification modelData

                                property bool dismissing: false
                                readonly property string iconSource: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                                readonly property bool hasIcon: iconSource !== ""
                                readonly property int iconSize: Math.max(Config.font_2xl * 3, 64)

                                color: Config.color_background
                                border.width: 1
                                border.color: Config.color_border
                                radius: Config.radius
                                Layout.preferredWidth: 400
                                Layout.rightMargin: Config.hyprland_gap
                                Layout.topMargin: Config.hyprland_gap
                                implicitHeight: notificationContent.implicitHeight + (Config.spacing_xl * 2)

                                RowLayout {
                                    id: notificationContent
                                    anchors.fill: notification
                                    anchors.margins: Config.spacing_xl
                                    spacing: notification.hasIcon ? Config.spacing_lg : 0

                                    Item {
                                        id: iconContainer
                                        Layout.preferredWidth: notification.hasIcon ? notification.iconSize : 0
                                        Layout.preferredHeight: notification.hasIcon ? notification.iconSize : 0
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: notification.hasIcon

                                        Image {
                                            id: iconImage
                                            anchors.fill: parent
                                            source: notification.iconSource
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            asynchronous: true
                                            cache: true
                                        }
                                    }

                                    ColumnLayout {
                                        id: notificationColumn
                                        Layout.fillWidth: true

                                        Text {
                                            text: notification.modelData.appName
                                            color: Config.color_muted_foreground
                                            Layout.fillWidth: true
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: Config.font_base
                                        }
                                        Text {
                                            text: notification.modelData.summary
                                            color: Config.color_foreground
                                            Layout.fillWidth: true
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: Config.font_xl
                                        }
                                        Text {
                                            text: notification.modelData.body
                                            color: Config.color_foreground
                                            font.pixelSize: Config.font_base
                                            Layout.fillWidth: true
                                            wrapMode: Text.WrapAnywhere
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => notification.startDismissal()
                                }

                                function startDismissal() {
                                    if (dismissing)
                                        return;

                                    dismissing = true;
                                    fadeOut.start();
                                }

                                Timer {
                                    id: autoDismissTimer
                                    interval: Config.notification_timeout
                                    running: notificationsWindow.visible && Config.notification_timeout > 0
                                    repeat: false
                                    onTriggered: notification.startDismissal()
                                }

                                SequentialAnimation {
                                    id: fadeOut
                                    PropertyAnimation {
                                        target: notification
                                        property: "opacity"
                                        to: 0
                                        duration: 300
                                        easing.type: Easing.InOutQuad
                                    }
                                    ScriptAction {
                                        script: NotificationsManager.dismissOne(notification.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
