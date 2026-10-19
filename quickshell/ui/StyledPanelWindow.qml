import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property string name

    WlrLayershell.namespace: `quickshell:${name}`
    color: "transparent"
}
