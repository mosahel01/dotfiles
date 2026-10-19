import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    spacing: 4

    Text {
        id: charginBolt
        text: ""
        font.pixelSize: Config.font_xxs
        color: {
            var percentage = UPower.displayDevice.percentage * 100;
            if (percentage > 50)
                return Config.color_green;
            else if (percentage > 20)
                return Config.color_amber;
            else
                return Config.color_red;
        }

        visible: UPower.displayDevice.state === UPowerDeviceState.Charging

        // Subtle pulsing animation when charging
        SequentialAnimation on opacity {
            running: charginBolt.visible
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.3
                duration: 1000
            }
            NumberAnimation {
                to: 1.0
                duration: 1000
            }
        }
    }

    Item {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 12

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: battery
                Layout.preferredWidth: 22
                Layout.preferredHeight: 12
                border.color: Config.color_foreground
                border.width: 1
                color: Config.color_transparent
                radius: 3

                Rectangle {
                    id: batteryFill
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: 2.3
                    }
                    width: Math.max(0, (parent.width - 4) * (UPower.displayDevice.percentage))
                    color: {
                        var percentage = UPower.displayDevice.percentage * 100;
                        if (percentage > 50)
                            return Config.color_green;
                        else if (percentage > 20)
                            return Config.color_amber;
                        else
                            return Config.color_red;
                    }
                    radius: 1.2

                    // Animate fill changes
                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
            }

            Rectangle {
                id: batteryTerminal
                Layout.preferredWidth: 2
                Layout.preferredHeight: 6
                color: Config.color_foreground
                radius: 3
            }
        }
    }

    // Battery percentage
    Text {
        text: {
            var percentage = Math.round(UPower.displayDevice.percentage * 100);
            return percentage + "%";
        }

        color: {
            var percentage = UPower.displayDevice.percentage * 100;
            if (percentage <= 10 && UPower.onBattery)
                return Config.color_red;
            else
                // Normal color
                return Config.color_foreground;  // Normal color
        }

        font.pixelSize: Config.font_sm
        font.weight: 600

        // Smooth color transitions
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }
}
