import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../osd"

Item {
    id: root
    Theme { id: theme }

    property var popupManager: null

    implicitWidth:  pillBg.implicitWidth
    implicitHeight: theme.barHeight

    property int    level:    0
    property bool   charging: false
    property bool   full:     false
    property string timeStr:  ""
    property bool   hovered:  false
    property bool   popupOpen: false

    readonly property bool isLow:  level <= theme.batWarnLevel && !charging && !full
    readonly property bool isCrit: level <= theme.batCritLevel && !charging && !full

    readonly property color fillColor: {
        if (full || charging) return theme.success
        if (isCrit)           return theme.danger
        if (isLow)            return theme.warning
        return theme.archCyan
    }

    Process {
        id: batProc
        command: ["sh", "-c",
            "cat /sys/class/power_supply/BAT0/capacity; echo '---';" +
            "cat /sys/class/power_supply/BAT0/status; echo '---';" +
            "cat /sys/class/power_supply/BAT0/energy_now; echo '---';" +
            "cat /sys/class/power_supply/BAT0/energy_full; echo '---';" +
            "cat /sys/class/power_supply/BAT0/power_now"
        ]

        property var vals: []

        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "---")
                    batProc.vals.push(line.trim())
            }
        }

        onStarted: {
            vals = []
        }

        onExited: {
            var v = vals
            if (v.length < 5) return

            root.level    = parseInt(v[0]) || 0
            root.charging = v[1] === "Charging"
            root.full     = v[1] === "Full"

            var eNow = parseInt(v[2])
            var eFull = parseInt(v[3])
            var pNow = parseInt(v[4])

            if (pNow > 0) {
                var t = root.charging ? (eFull - eNow) / pNow : eNow / pNow
                var h = Math.floor(t)
                var m = Math.round((t - h) * 60)
                root.timeStr = h > 0 ? h + "h " + m + "m" : m + "m"
            } else {
                root.timeStr = ""
            }
        }
    }

    Timer {
        interval: theme.battInterval
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            batProc.running = true
        }
    }

    SequentialAnimation {
        id: lowPulse
        running: root.isCrit
        loops: Animation.Infinite

        NumberAnimation { target: pillBg; property: "opacity"; from: 1.0; to: 0.45; duration: 600 }
        NumberAnimation { target: pillBg; property: "opacity"; from: 0.45; to: 1.0; duration: 600 }

        onRunningChanged: if (!running) pillBg.opacity = 1.0
    }

    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: innerRow.implicitWidth + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius

        color: root.hovered ? theme.bgHover : theme.bgSurface
        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Row {
            id: innerRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 6

            Text {
                text: root.full ? "✓" : "⚡"
                color: root.fillColor
                font.pixelSize: 13
                height: 16
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: root.full ? "Dolu" : root.level + "%"
                color: root.fillColor
                font.pixelSize: 12
                height: 16
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            root.hovered = hovered
            if (popupManager) {
                if (hovered)
                    popupManager.showOsd("battery")
                else
                    popupManager.dismissOsd("battery")
            }
        }
    }
    
    TapHandler { onTapped: root.popupOpen = !root.popupOpen }

    BatteryOSD {
        id: batteryOsd
        targetItem: pillBg
        timeStr: root.timeStr
        charging: root.charging
        full: root.full
    }

    property var osdPopup: batteryOsd
}
