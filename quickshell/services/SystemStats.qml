pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property Timer statsTimer: Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true

        property real cpuUsage: 0
        property real memoryUsage: 0

        onTriggered: root.updateStats()
    }

    readonly property real cpuUsage: statsTimer.cpuUsage
    readonly property real memoryUsage: statsTimer.memoryUsage

    property double _previousIdle: 0
    property double _previousTotal: 0
    property bool _hasPreviousSample: false

    FileView {
        id: cpuFile
        path: "/proc/stat"
        blockLoading: true
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        blockLoading: true
    }

    Component.onCompleted: updateStats()

    function updateStats() {
        updateCpuStats();
        updateMemoryStats();
    }

    function updateCpuStats() {
        var text = readFile(cpuFile);
        if (!text)
            return;

        var lines = text.split("\n");
        var cpuLine = null;
        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].startsWith("cpu ")) {
                cpuLine = lines[i];
                break;
            }
        }

        if (!cpuLine)
            return;

        var parts = cpuLine.trim().split(/\s+/);
        if (parts.length < 8)
            return;

        var user = Number(parts[1]);
        var nice = Number(parts[2]);
        var system = Number(parts[3]);
        var idle = Number(parts[4]);
        var iowait = Number(parts[5]);
        var irq = Number(parts[6]);
        var softirq = Number(parts[7]);
        var steal = parts.length > 8 ? Number(parts[8]) : 0;

        var idleTime = idle + iowait;
        var nonIdleTime = user + nice + system + irq + softirq + steal;
        var totalTime = idleTime + nonIdleTime;

        if (root._hasPreviousSample) {
            var totalDelta = totalTime - root._previousTotal;
            var idleDelta = idleTime - root._previousIdle;

            if (totalDelta > 0) {
                var usage = (totalDelta - idleDelta) / totalDelta * 100;
                statsTimer.cpuUsage = clampPercentage(usage);
            }
        }

        root._previousTotal = totalTime;
        root._previousIdle = idleTime;
        root._hasPreviousSample = true;
    }

    function updateMemoryStats() {
        var text = readFile(memFile);
        if (!text)
            return;

        var lines = text.split("\n");
        var memTotal = NaN;
        var memAvailable = NaN;

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i];
            if (line.startsWith("MemTotal:")) {
                memTotal = parseMemValue(line);
            } else if (line.startsWith("MemAvailable:")) {
                memAvailable = parseMemValue(line);
            } else if (line.startsWith("MemFree:") && isNaN(memAvailable)) {
                memAvailable = parseMemValue(line);
            }
        }

        if (isFinite(memTotal) && isFinite(memAvailable) && memTotal > 0) {
            var used = memTotal - memAvailable;
            statsTimer.memoryUsage = clampPercentage((used / memTotal) * 100);
        }
    }

    function parseMemValue(line) {
        var parts = line.split(":");
        if (parts.length < 2)
            return NaN;

        var valuePart = parts[1].trim().split(/\s+/)[0];
        var value = Number(valuePart);
        return isFinite(value) ? value : NaN;
    }

    function readFile(view) {
        try {
            view.reload();
            return view.text();
        } catch (error) {
            console.warn("Failed to read", view.path, error);
        }
        return "";
    }

    function clampPercentage(value) {
        if (!isFinite(value))
            return 0;
        if (value < 0)
            return 0;
        if (value > 100)
            return 100;
        return value;
    }
}
