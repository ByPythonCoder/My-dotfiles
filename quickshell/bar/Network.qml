import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "../osd"
import "../popups"

Item {
    id: root

    Theme { id: theme }

    property var popupManager: null

    implicitWidth: pillBg.width
    implicitHeight: theme.barHeight

    property string ssid: ""
    property int signalPct: 0
    property int signalBars: 0
    property string security: ""
    property bool connected: false
    property bool hovered: false

    function pctToBars(pct) {
        if (pct >= 80) return 4
        if (pct >= 55) return 3
        if (pct >= 30) return 2
        if (pct > 0) return 1
        return 0
    }

    function safeText(v, fallback) {
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : fallback
    }

    Process {
        id: nmcliProc
        command: ["sh", "-c", "LC_ALL=C nmcli -t -e no -f ACTIVE,SSID,SIGNAL,SECURITY device wifi list"]
        property bool foundActive: false

        stdout: SplitParser {
            onRead: line => {
                const raw = line.trim()
                if (!raw.length)
                    return

                const parts = raw.split(":")
                if (parts.length < 4)
                    return

                const active = parts[0] === "yes"
                if (!active)
                    return

                nmcliProc.foundActive = true
                root.connected = true
                root.ssid = root.safeText(parts.slice(1, parts.length - 2).join(":"), "Gizli Ağ")
                root.signalPct = parseInt(parts[parts.length - 2], 10) || 0
                root.signalBars = root.pctToBars(root.signalPct)
                root.security = root.safeText(parts[parts.length - 1], "Açık")
            }
        }

        onStarted: foundActive = false

        onExited: {
            if (!foundActive) {
                root.connected = false
                root.ssid = ""
                root.signalPct = 0
                root.signalBars = 0
                root.security = ""
            }
        }
    }

    Timer {
        interval: theme.netInterval || 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: nmcliProc.running = true
    }

    readonly property string displaySsid: {
        if (!root.connected)
            return "çevrimdışı"
        if ((root.ssid || "").length <= 14)
            return root.ssid
        return root.ssid.substring(0, 13) + "…"
    }

    function togglePopup() {
        if (popupManager)
            popupManager.toggleMajor("network")
    }

    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter
        width: root.hovered ? netIcon.width + 6 + netSsidText.width + theme.pillPaddingH * 2 : netIcon.width + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius
        color: root.hovered ? theme.bgHover : theme.bgSurface
        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: theme.animFast } }

        Row {
            id: innerRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 6

            Item {
                id: netIcon
                width: 13
                height: 13
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 4
                    Rectangle {
                        property int barH: [4, 6, 9, 13][index]
                        property bool lit: root.signalBars > index
                        width: 2.5
                        height: barH
                        radius: 1.2
                        x: index * 3.5
                        y: 13 - barH
                        color: lit ? theme.archCyan : Qt.rgba(1, 1, 1, 0.15)
                        opacity: root.connected ? 1.0 : 0.25

                        Behavior on color { ColorAnimation { duration: theme.animMed } }
                        Behavior on opacity { NumberAnimation { duration: theme.animMed } }
                    }
                }
            }

            Text {
                id: netSsidText
                text: root.displaySsid
                anchors.verticalCenter: parent.verticalCenter
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSm
                font.weight: theme.weightMed
                color: root.connected ? theme.textPrimary : theme.textDim
                visible: root.hovered
                opacity: root.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: theme.animMed } }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            root.hovered = hovered
            if (popupManager) {
                if (hovered && !networkPopup.visibleState)
                    popupManager.showOsd("network")
                else if (!hovered)
                    popupManager.dismissOsd("network")
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.togglePopup()
    }

    NetworkOSD {
        id: netOsd
        targetItem: pillBg
        connected: root.connected
        ssid: root.ssid
        signalPct: root.signalPct
        security: root.security
    }

    NetworkPopup {
        id: networkPopup
        targetItem: pillBg
    }

    property var netPopup: networkPopup
    property var osdPopup: netOsd
}
