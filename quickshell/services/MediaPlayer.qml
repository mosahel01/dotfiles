pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool isAvailable: _playerctlExecutableFound
    readonly property bool isPlaying: status === "Playing"
    readonly property bool hasMetadata: title.length > 0 || artist.length > 0
    readonly property bool hasActiveTrack: hasMetadata

    property string title: ""
    property string artist: ""
    property string status: ""
    property string playerName: ""
    property real positionSeconds: 0
    property real lengthSeconds: 0

    readonly property string displayText: {
        if (hasMetadata) {
            var text = title.length > 0 ? title : ""
            if (artist.length > 0) {
                text = text.length > 0 ? text + " - " + artist : artist
            }
            if (!isPlaying && status.length > 0) {
                text += " (" + status + ")"
            }
            return text.length > 0 ? text : "Media"
        }
        if (isAvailable)
            return "No media playing"
        return "No media sources"
    }

    readonly property string timeDisplay: {
        if (!hasMetadata)
            return ""
        var current = formatDuration(positionSeconds)
        var total = lengthSeconds > 0 ? formatDuration(lengthSeconds) : "--:--"
        return current + "/" + total
    }

    readonly property var _metadataCommand: [
        "playerctl",
        "--follow",
        "metadata",
        "--format",
        "{{status}}\t{{playerName}}\t{{xesam:artist}}\t{{xesam:title}}\t{{position}}\t{{mpris:length}}"
    ]

    property bool _playerctlExecutableFound: false
    property bool _monitorActive: true

    component MonitorParser: SplitParser {
        splitMarker: "\n"
        onRead: function(line) {
            root._handleMetadata(line)
        }
    }

    Process {
        id: metadataProcess
        command: root._metadataCommand
        running: root._monitorActive
        stdout: MonitorParser {}

        onStarted: root._playerctlExecutableFound = true

        onExited: function(exitCode) {
            if (exitCode === 127)
                root._playerctlExecutableFound = false
            root._scheduleMonitorRestart()
        }
    }

    Process {
        id: commandRunner
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!root._monitorActive) {
                root._monitorActive = true
            }
        }
    }

    function _handleMetadata(rawLine) {
        if (!rawLine)
            return

        var line = rawLine.trim()
        if (line.length === 0)
            return

        if (line.startsWith("No players"))
            return _clearMetadata()

        var parts = line.split("\t")
        if (parts.length < 4)
            return

        status = parts[0] || ""
        playerName = parts[1] || ""
        artist = parts[2] || ""
        title = parts[3] || ""

        var positionValue = parts.length > 4 ? Number(parts[4]) : NaN
        var lengthValue = parts.length > 5 ? Number(parts[5]) : NaN

        if (isFinite(positionValue))
            positionSeconds = Math.max(0, positionValue / 1000000)
        else
            positionSeconds = 0

        if (isFinite(lengthValue))
            lengthSeconds = Math.max(0, lengthValue / 1000000)
        else
            lengthSeconds = 0
    }

    function _clearMetadata() {
        title = ""
        artist = ""
        status = ""
        playerName = ""
        positionSeconds = 0
        lengthSeconds = 0
    }

    function _scheduleMonitorRestart() {
        _clearMetadata()
        if (restartTimer.running)
            return
        _monitorActive = false
        restartTimer.start()
    }

    function _sendCommand(args) {
        if (!args || args.length === 0)
            return

        var command = ["playerctl"]
        if (playerName.length > 0)
            command.push("--player", playerName)
        for (var i = 0; i < args.length; i++) {
            command.push(args[i])
        }
        commandRunner.exec(command)
    }

    function playPause() {
        _sendCommand(["play-pause"])
    }

    function play() {
        _sendCommand(["play"])
    }

    function pause() {
        _sendCommand(["pause"])
    }

    function next() {
        _sendCommand(["next"])
    }

    function previous() {
        _sendCommand(["previous"])
    }

    Timer {
        id: positionTimer
        interval: 1000
        repeat: true
        running: root.isPlaying && root.hasMetadata
        onTriggered: root._tickPosition(interval / 1000)
    }

    function _tickPosition(deltaSeconds) {
        if (!root.isPlaying)
            return
        if (!isFinite(root.positionSeconds))
            root.positionSeconds = 0
        var nextValue = root.positionSeconds + deltaSeconds
        if (root.lengthSeconds > 0) {
            root.positionSeconds = Math.min(root.lengthSeconds, nextValue)
        } else {
            root.positionSeconds = nextValue
        }
    }

    function formatDuration(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            seconds = 0
        var totalSeconds = Math.floor(seconds)
        var minutes = Math.floor(totalSeconds / 60)
        var secs = totalSeconds % 60
        var padded = secs < 10 ? "0" + secs : String(secs)
        return minutes + ":" + padded
    }
}
