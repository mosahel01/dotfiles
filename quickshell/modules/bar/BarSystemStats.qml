import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    spacing: Config.spacing_md
    Layout.alignment: Qt.AlignVCenter

    function formatPercentage(value) {
        if (!isFinite(value))
            return "--";
        return Math.round(value) + "%";
    }

    function usageColor(value) {
        if (!Config.colorize_system_stats || !isFinite(value))
            return Config.color_foreground;

        const palette = Config.system_stats_palette;

        if (value < 40)
            return palette.low;
        if (value < 70)
            return palette.medium;
        if (value < 85)
            return palette.high;
        return palette.critical;
    }

    Text {
        text: "\uf4bc  CPU " + root.formatPercentage(SystemStats.cpuUsage)
        color: root.usageColor(SystemStats.cpuUsage)
        font.pointSize: Config.font_xs
        font.weight: 600
    }

    Text {
        text: "\udb80\udf5b RAM " + root.formatPercentage(SystemStats.memoryUsage)
        color: root.usageColor(SystemStats.memoryUsage)
        font.pointSize: Config.font_xs
        font.weight: 600
    }
}
