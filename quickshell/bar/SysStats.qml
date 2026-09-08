import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "../osd"

Item {
    id: root
    property var statsPopup: statsOsd
    property var popupManager: null
    Theme { id: theme }

    implicitWidth:  statsRow.implicitWidth
    implicitHeight: theme.barHeight

    property real cpuPercent:    0
    property real ramPercent:    0
    property real ramUsedBytes:  0
    property real ramTotalBytes: 0
    property var  prevIdle:      0
    property var  prevTotal:     0
    property bool hovered:       false
    property var  cpuHistory:    []
    property string uptimeStr:   "…"

    // CPU via /proc/stat
    Process {
        id: statProc
        command: ["sh", "-c", "head -1 /proc/stat"]

        stdout: SplitParser {
            onRead: (line) => {
                var p = line.trim().split(/\s+/)
                if (p.length < 8) return
                var idle  = parseInt(p[4]) + parseInt(p[5])
                var busy  = parseInt(p[1]) + parseInt(p[2]) + parseInt(p[3]) +
                            parseInt(p[6]) + parseInt(p[7]) + (p[8] ? parseInt(p[8]) : 0)
                var total = idle + busy
                var dT    = total - root.prevTotal
                var dI    = idle  - root.prevIdle
                if (dT > 0) root.cpuPercent = Math.round(((dT - dI) / dT) * 100)
                root.prevTotal = total
                root.prevIdle  = idle
                var h = root.cpuHistory.slice()
                h.push(root.cpuPercent)
                if (h.length > 20) h.shift()
                root.cpuHistory = h
                if (statsOsd.osdVisible) sparkCanvas.requestPaint()
            }
        }
    }

    // RAM via /proc/meminfo
    Process {
        id: memProc
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        property int mtotal: 0
        property int mavail: 0
        stdout: SplitParser {
            onRead: (line) => {
                if (line.startsWith("MemTotal:"))     memProc.mtotal = parseInt(line.replace(/[^0-9]/g,""))
                if (line.startsWith("MemAvailable:")) memProc.mavail = parseInt(line.replace(/[^0-9]/g,""))
            }
        }
        onExited: {
            if (memProc.mtotal > 0) {
                root.ramTotalBytes = memProc.mtotal * 1024
                root.ramUsedBytes  = (memProc.mtotal - memProc.mavail) * 1024
                root.ramPercent    = Math.round(root.ramUsedBytes / root.ramTotalBytes * 100)
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["sh", "-c", "cat /proc/uptime"]
        stdout: SplitParser {
            onRead: (line) => {
                var secs = Math.floor(parseFloat(line.trim().split(" ")[0]))
                var h = Math.floor(secs / 3600)
                var m = Math.floor((secs % 3600) / 60)
                root.uptimeStr = h + "h " + m + "m"
            }
        }
    }

    // Poll timer
    Timer {
        interval: theme.statsInterval
        running:  true; repeat: true; triggeredOnStart: true
        onTriggered: {
            statProc.running = true
            memProc.running = true
            uptimeProc.running = true
        }
    }

    function cpuColor(p) {
        if (p >= 90) return theme.danger
        if (p >= 70) return theme.warning
        return theme.archCyan
    }
    function ramColor(p) {
        if (p >= 90) return theme.danger
        if (p >= 75) return theme.warning
        return theme.archBlue
    }

    Row {
        id: statsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: theme.gap

        StatPill {
            label:   "CPU"
            value:   root.cpuPercent + "%"
            barFrac: root.cpuPercent / 100
            barCol:  root.cpuColor(root.cpuPercent)
            hov:     root.hovered
            onClicked: { if (popupManager) popupManager.toggleMajor("stats") }
        }

        StatPill {
            label:   "RAM"
            value:   theme.formatRam(root.ramUsedBytes)
            barFrac: root.ramPercent / 100
            barCol:  root.ramColor(root.ramPercent)
            hov:     root.hovered
            onClicked: { if (popupManager) popupManager.toggleMajor("stats") }
        }
    }

    HoverHandler { onHoveredChanged: root.hovered = hovered }

    // Stats OSD
    PopupWindow {
        id: statsOsd

        property bool osdVisible: false
        function open() { osdVisible = true }
        function close() { osdVisible = false }
        function toggle() { osdVisible = !osdVisible }

        color:   "transparent"
        visible: osdVisible || osdContainer.opacity > 0.001

        anchor {
            item: statsRow
	    edges: (Edges.Bottom | Edges.HorizontalCenter)
	    gravity: (Edges.Bottom | Edges.HorizontalCenter)
        }

        implicitWidth:  260
        implicitHeight: 260

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                var cp = mapToItem(osdContainer, mouse.x, mouse.y)
                if (!osdContainer.contains(cp))
                    statsOsd.close()
                else
                    mouse.accepted = false
            }
        }

        Rectangle {
            id: osdContainer
            width:  240
            radius: 14
            color:  Qt.rgba(0.06, 0.07, 0.09, 0.92)
            border.width: 1
            border.color: Qt.rgba(0.09, 0.58, 0.82, 0.3)
            height: osdCol.implicitHeight + 24

            anchors.horizontalCenter: parent.horizontalCenter

            opacity: statsOsd.osdVisible ? 1.0 : 0.0
            scale:   statsOsd.osdVisible ? 1.0 : 0.93
            
	          y:       statsOsd.osdVisible ? 6 : -40

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack  } }
            Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Column {
                id: osdCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                Text {
                    text: "System"
                    font.pixelSize: 11; font.weight: Font.Medium
                    color: "#00b4d8"
                }

                RowLayout {
                    width: parent.width
                    Text { text: "CPU"; font.pixelSize: 10; color: "#7d8590" }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.cpuPercent + "%"
                        font.pixelSize: 10; font.weight: Font.Medium
                        color: root.cpuColor(root.cpuPercent)
                    }
                }

                Canvas {
                    id: sparkCanvas
                    width: parent.width; height: 36

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var h = root.cpuHistory
                        if (h.length < 2) return

                        ctx.beginPath()
                        for (var i = 0; i < h.length; i++) {
                            var x = (i / (h.length - 1)) * width
                            var y = height - (h[i] / 100) * (height - 4) - 2
                            i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
                        }
                        ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.closePath()
                        ctx.fillStyle = Qt.rgba(0.09, 0.58, 0.82, 0.15)
                        ctx.fill()

                        ctx.beginPath()
                        for (var j = 0; j < h.length; j++) {
                            var x2 = (j / (h.length - 1)) * width
                            var y2 = height - (h[j] / 100) * (height - 4) - 2
                            j === 0 ? ctx.moveTo(x2, y2) : ctx.lineTo(x2, y2)
                        }
                        ctx.strokeStyle = "#1793d1"
                        ctx.lineWidth   = 1.5
                        ctx.stroke()
                    }
                }

                RowLayout {
                    width: parent.width
                    Text { text: "RAM"; font.pixelSize: 10; color: "#7d8590" }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: theme.formatRam(root.ramUsedBytes) + " / " + theme.formatRam(root.ramTotalBytes)
                        font.pixelSize: 10; font.weight: Font.Medium
                        color: root.ramColor(root.ramPercent)
                    }
                }

                Rectangle {
                    width: parent.width; height: 5; radius: 3
                    color: Qt.rgba(1,1,1,0.07)
                    Rectangle {
                        width:  parent.width * (root.ramPercent / 100)
                        height: parent.height; radius: 3
                        color:  root.ramColor(root.ramPercent)
                        Behavior on width { NumberAnimation { duration: theme.animMed } }
                    }
                }

                Rectangle { width: parent.width; height: 0.5; color: Qt.rgba(0.09,0.58,0.82,0.2) }

                RowLayout {
                    width: parent.width
                    Text { text: "Uptime"; font.pixelSize: 10; color: "#7d8590" }
                    Item { Layout.fillWidth: true }
                    Text { text: root.uptimeStr; font.pixelSize: 10; color: "#e6edf3" }
                }
            }
        }
}
}
