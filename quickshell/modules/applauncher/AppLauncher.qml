pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.config
import qs.ui

Scope {
    id: scope
    property bool opened: false

    LazyLoader {
        active: scope.opened

        StyledPanelWindow {
            id: window
            name: "applauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            Rectangle {
                id: windowBackground
                color: "black"
                anchors.fill: parent
                opacity: 0.3
            }

            WrapperRectangle {
                id: launcher
                color: Config.color_background
                radius: Config.radius_lg
                implicitWidth: launcherContent.implicitWidth
                implicitHeight: launcherContent.implicitHeight
                y: window.height / 10
                anchors.horizontalCenter: parent.horizontalCenter

                ColumnLayout {
                    id: launcherContent

                    StyledTextField {
                        id: searchField
                        Layout.preferredWidth: 500
                        Layout.preferredHeight: 40
                        cursorVisible: true
                        focus: window.visible
                        placeholderText: "Applications"
                        placeholderTextColor: "grey"

                        Keys.onPressed: event => {
                            if (event.modifiers & Qt.ControlModifier) {
                                switch (event.key) {
                                case Qt.Key_K:
                                    applist.decrementCurrentIndex();
                                    return;
                                case Qt.Key_J:
                                    applist.incrementCurrentIndex();
                                    return;
                                }
                            } else {
                                switch (event.key) {
                                case Qt.Key_Escape:
                                    scope.reset();
                                    return;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    scope.launchApp(applist.currentItem.modelData);
                                    return;
                                case Qt.Key_Up:
                                    applist.decrementCurrentIndex();
                                    return;
                                case Qt.Key_Down:
                                    applist.incrementCurrentIndex();
                                    return;
                                }
                            }
                        }
                    }

                    WrapperRectangle {
                        Layout.preferredWidth: 600
                        Layout.preferredHeight: 300
                        color: Config.color_transparent

                        StyledListView {
                            id: applist
                            spacing: 10
                            anchors.fill: parent

                            model: ScriptModel {
                                id: model
                                onValuesChanged: {
                                    applist.currentIndex = 0;
                                }
                                values: DesktopEntries.applications.values.filter(a => a.name.toLowerCase().includes(searchField.text.toLowerCase()))
                            }

                            delegate: Text {
                                id: application
                                required property DesktopEntry modelData

                                color: ListView.isCurrentItem ? "blue" : "white"
                                text: application.modelData.name

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {}
                                }
                            }
                        }
                    }
                }
            }

            HyprlandFocusGrab {
                active: window.visible
                windows: [searchField]
                onCleared: {
                    console.log("TODO: grab cleared");
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle() {
            scope.opened = !scope.opened;
        }
    }

    function reset() {
        opened = false;
    }

    function launchApp(app: DesktopEntry) {
        reset();
        app.execute();
    }
}
