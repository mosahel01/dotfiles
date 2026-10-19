import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config

RowLayout {
    spacing: Config.spacing_base

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: button
            required property HyprlandWorkspace modelData
            property bool isHovered: false

            width: 18
            height: 18
            radius: 6

            color: {
                if (button.modelData === Hyprland.focusedWorkspace) {
                    return Config.color_foreground;
                }
                if (button.isHovered) {
                    return Config.color_primary;
                }
                return Config.color_transparent;
            }

            Text {
                anchors.centerIn: parent
                font.pixelSize: Config.font_xs
                font.weight: {
                    if (button.modelData === Hyprland.focusedWorkspace) {
                        return 800;
                    }
                    return 400;
                }
                color: {
                    if (button.modelData === Hyprland.focusedWorkspace) {
                        return Config.color_background;
                    }
                    return Config.color_foreground;
                }
                text: button.modelData.name
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    Hyprland.dispatch("workspace " + button.modelData.name);
                }

                // Hover effect
                onEntered: {
                    if (button.modelData === Hyprland.focusedWorkspace) {
                        return;
                    }
                    cursorShape = Qt.PointingHandCursor;
                    parent.isHovered = true;
                }

                onExited: {
                    parent.isHovered = false;
                }
            }
        }
    }
}
