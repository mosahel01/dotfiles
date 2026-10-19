pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.config
import qs.ui
import Quickshell.Io

Scope {
    id: scope

    property bool opened: false

    IpcHandler {
        target: "launcher"
        function toggle() {
            scope.opened = !scope.opened;
        }
    }

    function close() {
        scope.opened = false;
    }

    LazyLoader {
        active: scope.opened

        StyledPanelWindow {
            id: window
            name: "applauncher"

            property int launcher_width: 700
            property int launcher_max_height: 400

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Launcher {
                implicitWidth: window.launcher_width
                implicitHeight: launcherColumn.implicitHeight
                y: window.height / 10

                LauncherColumn {
                    id: launcherColumn
                    margins: 40

                    SearchField {
                        id: searchField
                        focus: window.visible
                        Layout.fillWidth: true

                        Keys.onPressed: event => {
                            if (event.modifiers & Qt.ControlModifier) {
                                switch (event.key) {
                                case Qt.Key_K:
                                    appList.decrementCurrentIndex();
                                    return;
                                case Qt.Key_J:
                                    appList.incrementCurrentIndex();
                                    return;
                                }
                            } else {
                                switch (event.key) {
                                case Qt.Key_Escape:
                                    scope.close();
                                    return;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    appList.currentItem.modelData.execute();
                                    scope.close();
                                    return;
                                case Qt.Key_Up:
                                    appList.decrementCurrentIndex();
                                    return;
                                case Qt.Key_Down:
                                    appList.incrementCurrentIndex();
                                    return;
                                }
                            }
                        }
                    }

                    AppList {
                        id: appList
                        searchQuery: searchField.text

                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        Layout.maximumHeight: window.launcher_max_height
                    }
                }
            }
        }
    }

    // Components
    component SearchField: StyledTextField {
        cursorVisible: true
        placeholderText: "Applications"
        placeholderTextColor: "grey"
        font.pointSize: 20
    }

    component Launcher: WrapperRectangle {
        id: root

        color: Config.color_background
        radius: 40
        anchors {
            horizontalCenter: parent.horizontalCenter
        }
    }

    component LauncherColumn: ColumnLayout {
        id: root
        default property alias contents: innerLayout.children
        property int margins: 10

        ColumnLayout {
            id: innerLayout
            Layout.margins: root.margins
            spacing: 40
            clip: true
            // Content declared in LauncherColumn {...} will appear here with margins!
        }
    }

    component AppList: ListView {
        id: root
        required property string searchQuery

        clip: true
        spacing: 10
        highlightMoveDuration: 0

        model: DesktopEntries.applications.values.filter(a => a.name.toLowerCase().includes(searchQuery))

        delegate: WrapperRectangle {
            id: appDelegate

            required property DesktopEntry modelData
            required property string name
            required property string comment
            required property string icon

            implicitWidth: ListView.view.width
            radius: 20
            color: appDelegate.ListView.isCurrentItem ? "#14161B" : "transparent"

            // Margin wrapper (anchors.margins break row for some reason)
            ColumnLayout {
                anchors.fill: parent

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 20
                    spacing: 20

                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 50
                        Layout.alignment: Qt.AlignTop
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: Quickshell.iconPath(appDelegate.icon, true)
                            visible: source != ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            cache: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            color: Config.color_foreground
                            wrapMode: Text.WrapAnywhere
                            font.pointSize: Config.font_lg

                            text: appDelegate.name
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: Config.color_muted_foreground

                            text: appDelegate.comment
                        }
                    }
                }
            }
        }
    }
}
