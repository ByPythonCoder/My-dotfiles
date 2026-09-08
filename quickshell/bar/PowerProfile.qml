import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "../osd"

Item {
    id: root
    Theme { id: theme }

    property var popupManager: null

    implicitWidth: pillBg.width
    implicitHeight: theme.barHeight

    property bool hovered: false
    property string currentProfile: "balanced"
    property bool _ready: false

    readonly property var profiles: ["power-saver", "balanced", "performance"]
    readonly property var profileIcons: {
        "power-saver": "\uF0E7",
        "balanced": "\uF135",
        "performance": "\uF0E8"
    }
    readonly property var profileLabels: {
        "power-saver": "Tasarruf",
        "balanced": "Dengeli",
        "performance": "Performans"
    }
    readonly property var profileColors: {
        "power-saver": theme.green,
        "balanced": theme.archCyan,
        "performance": theme.peach
    }

    Process {
        id: readProc
        command: ["sh", "-c", "LC_ALL=C powerprofilesctl get"]

        property var output: ""

        stdout: SplitParser {
            onRead: function(line) {
                readProc.output += line.trim()
            }
        }

        onStarted: output = ""

        onExited: function(exitCode) {
            var profile = readProc.output.trim()
            if (profile.length > 0 && profile !== root.currentProfile) {
                root.currentProfile = profile
            }
            if (!root._ready)
                Qt.callLater(function() { root._ready = true })
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true

        onTriggered: {
            if (readProc.running) return
            readProc.running = true
        }
    }

    Component.onCompleted: readProc.running = true

    Process {
        id: setProc
    }

    function cycleProfile() {
        var idx = profiles.indexOf(currentProfile)
        var next = profiles[(idx + 1) % profiles.length]
        setProc.command = ["powerprofilesctl", "set", next]
        setProc.running = true
        currentProfile = next
    }

    function setProfile(name) {
        if (name === currentProfile) return
        setProc.command = ["powerprofilesctl", "set", name]
        setProc.running = true
        currentProfile = name
    }

    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter
        width: root.hovered ? ppIcon.width + 5 + ppLabel.width + theme.pillPaddingH * 2 : ppIcon.width + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius
        color: root.hovered ? theme.bgHover : theme.bgSurface
        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: theme.animFast } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Text {
                id: ppIcon
                text: root.profileIcons[root.currentProfile] || "\uF135"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: root.profileColors[root.currentProfile] || theme.archCyan
            }

            Text {
                id: ppLabel
                text: root.profileLabels[root.currentProfile] || root.currentProfile
                font.family: theme.fontFamily
                font.pixelSize: theme.fontBase
                color: root.profileColors[root.currentProfile] || theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hovered
                opacity: root.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        anchors.fill: pillBg
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onContainsMouseChanged: root.hovered = containsMouse

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.cycleProfile()
            } else if (mouse.button === Qt.RightButton) {
                var idx = root.profiles.indexOf(root.currentProfile)
                var prev = root.profiles[(idx - 1 + root.profiles.length) % root.profiles.length]
                root.setProfile(prev)
            }
        }
    }
}
