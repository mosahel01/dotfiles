pragma Singleton
import QtQuick

QtObject {
    readonly property int bar_height: 30
    readonly property int hyprland_gap: 8

    readonly property color color_transparent: "transparent"
    readonly property color color_background: "#1E1E1E"
    readonly property color color_foreground: "#ffffff"
    readonly property color color_muted_foreground: "gray"
    readonly property color color_primary: "#3498db"
    readonly property color color_secondary: "#2ecc71"
    readonly property color color_accent: "#e74c3c"

    readonly property color color_border: "gray"

    readonly property color color_green: "#2ecc71"
    readonly property color color_amber: "#f39c12"
    readonly property color color_red: "#e74c3c"
    readonly property color color_blue: "#3498db"
    readonly property color color_yellow: "#F7D720"

    readonly property var system_stats_palette: ({
        low: "#4FC3F7",
        medium: "#2ECC71",
        high: "#F1C40F",
        critical: "#E74C3C"
    })

    // Toggle entire system stats widget on the bar.
    readonly property bool show_system_stats: true

    // Toggle usage-based accenting for bar system stats.
    readonly property bool colorize_system_stats: true

    // Toggle track title/time display on the bar.
    readonly property bool show_media_track_info: true

    // Toggle only the playback controls while still allowing track info.
    readonly property bool show_media_controls: true

    // Toggle display of current playback time beside track title.
    readonly property bool show_media_time: false

    // Duration (ms) before notifications auto-dismiss; set to 0 to disable auto dismiss.
    readonly property int notification_timeout: 3000

    readonly property int font_base: 14

    readonly property int font_xxs: font_base - 6
    readonly property int font_xs: font_base - 4
    readonly property int font_sm: font_base - 2
    readonly property int font_lg: font_base + 2
    readonly property int font_xl: font_base + 4
    readonly property int font_2xl: font_base + 8

    readonly property int spacing_base: 6
    readonly property int spacing_md: spacing_base + 2
    readonly property int spacing_lg: spacing_base + 4
    readonly property int spacing_xl: spacing_base + 6
    readonly property int spacing_2xl: spacing_base + 8
    readonly property int spacing_3xl: spacing_base + 10
    readonly property int spacing_4xl: spacing_base + 12
    readonly property int spacing_5xl: spacing_base + 14

    readonly property int radius_base: 6
    readonly property int radius_sm: radius_base - 2
    readonly property int radius: radius_base
    readonly property int radius_lg: radius_base + 2
}
