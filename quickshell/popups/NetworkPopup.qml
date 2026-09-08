import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."
import ".."
import "../components"

PopupWindow {
    id: rootPopup

    property var targetItem: null
    property bool visibleState: false
    property var networks: []
    property string currentSsid: ""
    property bool wifiEnabled: true
    property bool scanning: false

    signal requestSecureConnect(string ssid, string security)

    property alias connectDialog: connectDialog

    property var _currentNetworks: []
    property var _availableNetworks: []

    color: "transparent"
    implicitWidth: 330
    implicitHeight: 470
    visible: visibleState || container.opacity > 0.001
    grabFocus: true

    anchor {
        item: rootPopup.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
        margins.top: 10
    }

    function open() {
        visibleState = true
        if (anchor && anchor.updateAnchor)
            anchor.updateAnchor()
        refreshRadio()
        refreshCurrent()
        rescan()
    }

    function close() {
        visibleState = false
    }

    function safeText(v, fallback) {
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : fallback
    }

    function safeInt(v, fallback) {
        var n = parseInt(v, 10)
        return isNaN(n) ? fallback : n
    }

    function splitNmcliTerse(line) {
        var out = []
        var cur = ""
        var escaping = false

        for (var i = 0; i < line.length; ++i) {
            var ch = line[i]
            if (escaping) {
                cur += ch
                escaping = false
            } else if (ch === "\\") {
                escaping = true
            } else if (ch === ":") {
                out.push(cur)
                cur = ""
            } else {
                cur += ch
            }
        }

        out.push(cur)
        return out
    }

    function sortNetworks(list) {
        return list.slice().sort(function(a, b) {
            if (!!a.active !== !!b.active)
                return a.active ? -1 : 1
            if ((a.ssid || "") !== (b.ssid || ""))
                return (a.ssid || "").localeCompare(b.ssid || "")
            return (b.signal || 0) - (a.signal || 0)
        })
    }

    function uniqueNetworks(list) {
        var out = []
        var seen = {}

        for (var i = 0; i < list.length; ++i) {
            var n = list[i]
            if (!n)
                continue

            var key = (n.bssid && n.bssid.length > 0) ? n.bssid : (n.ssid || "")
            if (!(key in seen)) {
                seen[key] = out.length
                out.push(n)
            } else {
                var idx = seen[key]
                var existing = out[idx]
                out[idx] = {
                    active: !!existing.active || !!n.active,
                    ssid: existing.ssid || n.ssid,
                    bssid: existing.bssid || n.bssid,
                    signal: Math.max(existing.signal || 0, n.signal || 0),
                    security: existing.security || n.security,
                    secure: !!existing.secure || !!n.secure
                }
            }
        }

        return out
    }

    function syncNetworkLists() {
        var cur = []
        var avail = []

        for (var i = 0; i < networks.length; ++i) {
            var n = networks[i]
            if (!!n.active)
                cur.push(n)
            else
                avail.push(n)
        }

        _currentNetworks = cur
        _availableNetworks = avail
    }

    function updateNetworks(list) {
        networks = sortNetworks(list)
        syncNetworkLists()
    }

    function refreshCurrent() {
        if (currentProc.running) return
        currentProc.running = true
    }

    function refreshRadio() {
        if (radioStateProc.running) return
        radioStateProc.running = true
    }

    function rescan() {
        if (!wifiEnabled) return
        if (rescanProc.running) return
        scanning = true
        rescanProc.running = true
    }

    function connectNetwork(network) {
        if (!network)
            return

        var ssid = safeText(network.ssid, "")
        var bssid = safeText(network.bssid, "")

        if (ssid.length === 0 || ssid === "Hidden Network")
            return

        if (!network.secure) {
            if (connectOpenProc.running) return
            connectOpenProc.ssid = ssid
            connectOpenProc.bssid = bssid
            connectOpenProc.errorOutput = ""
            connectOpenProc.running = true
        } else {
            connectDialog.previousSsid = rootPopup.currentSsid
            requestSecureConnect(ssid, network.security)
        }
    }

    function setWifiEnabled(enabled) {
        if (wifiToggleProc.running) return
        wifiToggleProc.enabledTarget = enabled
        wifiToggleProc.running = true
    }

    Process {
        id: currentProc
        command: ["sh", "-c", "LC_ALL=C nmcli -t -e yes -f ACTIVE,SSID device wifi list"]
        property var rawLines: []
        property string foundSsid: ""
        property string errorOutput: ""

        stdout: SplitParser {
            onRead: line => {
                if (line.length > 0)
                    currentProc.rawLines.push(line)
            }
        }

        stderr: SplitParser {
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length > 0)
                    currentProc.errorOutput += (currentProc.errorOutput.length > 0 ? "\n" : "") + trimmed
            }
        }

        onStarted: {
            rawLines = []
            foundSsid = ""
            errorOutput = ""
        }

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var found = ""

            for (var i = 0; i < rawLines.length; ++i) {
                var parts = rootPopup.splitNmcliTerse(rawLines[i])
                while (parts.length < 2)
                    parts.push("")

                var active = parts[0]
                var ssid = parts[1]

                if (active === "yes") {
                    found = ssid
                    break
                }
            }

            foundSsid = found
            rootPopup.currentSsid = found
        }
    }

    Process {
        id: rescanProc
        command: ["sh", "-c", "LC_ALL=C nmcli device wifi rescan >/dev/null 2>&1; LC_ALL=C nmcli -t -e yes -f ACTIVE,SSID,BSSID,SIGNAL,SECURITY device wifi list"]
        property var rawLines: []
        property string errorOutput: ""

        function normalize(parts) {
            var security = rootPopup.safeText(parts[4], "Open")
            return {
                active: parts[0] === "yes",
                ssid: rootPopup.safeText(parts[1], "Hidden Network"),
                bssid: rootPopup.safeText(parts[2], ""),
                signal: rootPopup.safeInt(parts[3], 0),
                security: security,
                secure: security !== "Open" && security !== "--" && security !== ""
            }
        }

        stdout: SplitParser {
            onRead: line => {
                if (line.length > 0)
                    rescanProc.rawLines.push(line)
            }
        }

        stderr: SplitParser {
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length > 0)
                    rescanProc.errorOutput += (rescanProc.errorOutput.length > 0 ? "\n" : "") + trimmed
            }
        }

        onStarted: {
            rawLines = []
            errorOutput = ""
        }

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return

            var parsed = []

            for (var i = 0; i < rawLines.length; ++i) {
                var parts = rootPopup.splitNmcliTerse(rawLines[i])
                while (parts.length < 5)
                    parts.push("")
                parsed.push(normalize(parts))
            }

            var uniq = rootPopup.uniqueNetworks(parsed)
            rootPopup.updateNetworks(uniq)
            rootPopup.scanning = false
            rootPopup.refreshCurrent()
        }
    }

    Process {
        id: connectOpenProc
        property string ssid: ""
        property string bssid: ""
        property string errorOutput: ""
        command: bssid.length > 0
                 ? ["nmcli", "device", "wifi", "connect", ssid, "bssid", bssid]
                 : ["nmcli", "device", "wifi", "connect", ssid]
        running: false

        stderr: SplitParser {
            onRead: line => {
                var trimmed = line.trim()
                if (trimmed.length > 0)
                    connectOpenProc.errorOutput += (connectOpenProc.errorOutput.length > 0 ? "\n" : "") + trimmed
            }
        }

        onStarted: errorOutput = ""

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            rootPopup.refreshCurrent()
            rootPopup.rescan()
        }
    }

    Process {
        id: wifiToggleProc
        property bool enabledTarget: true
        command: ["nmcli", "radio", "wifi", enabledTarget ? "on" : "off"]
        running: false

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            rootPopup.wifiEnabled = enabledTarget
            if (enabledTarget)
                rootPopup.rescan()
            else {
                rootPopup.networks = []
                rootPopup.syncNetworkLists()
            }
        }
    }

    Process {
        id: disconnectProc
        command: ["sh", "-c", "nmcli -t -f NAME,DEVICE,TYPE connection show --active | awk -F: '$NF == \"wifi\" {print $1; exit}' | xargs -r nmcli connection down"]
        running: false
        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            rootPopup.refreshCurrent()
            rootPopup.rescan()
        }
    }

    Process {
        id: radioStateProc
        command: ["sh", "-c", "LC_ALL=C nmcli radio wifi"]
        property string value: ""

        stdout: SplitParser {
            onRead: line => {
                radioStateProc.value = line.trim().toLowerCase()
            }
        }

        onStarted: value = ""

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            rootPopup.wifiEnabled = (value === "enabled")
        }
    }

    GlassPanel {
        id: container
        width: 320
        height: Math.min(446, contentCol.implicitHeight + 28)
        glassRadius: 14
        glassColor: Qt.rgba(0.12, 0.12, 0.18, 0.85)
        glassBorder: Qt.rgba(1, 1, 1, 0.08)
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.97
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: container.glassRadius
            clip: true
            color: container.glassColor
            layer.enabled: true

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Wi‑Fi"
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(1, 1, 1, 0.94)
                        }

                        Text {
                            text: rootPopup.wifiEnabled
                                  ? rootPopup.safeText(rootPopup.currentSsid, "Açık")
                                  : "Kapalı"
                            font.pixelSize: 10
                            color: rootPopup.wifiEnabled ? theme.accentActive : Qt.rgba(1, 1, 1, 0.40)
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: toggleTrack
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        width: 38
                        height: 20
                        radius: 10
                        color: rootPopup.wifiEnabled ? theme.accentActive : Qt.rgba(1, 1, 1, 0.10)
                        scale: toggleTap.pressed ? 0.97 : 1.0

                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.95)
                            anchors.verticalCenter: parent.verticalCenter
                            x: rootPopup.wifiEnabled ? 20 : 2

                            Behavior on x {
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }
                        }

                        TapHandler {
                            id: toggleTap
                            onTapped: rootPopup.setWifiEnabled(!rootPopup.wifiEnabled)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                Text {
                    visible: rootPopup.wifiEnabled && rootPopup._currentNetworks.length > 0
                    text: "Mevcut Ağ"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.42)
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: rootPopup.wifiEnabled && rootPopup._currentNetworks.length > 0

                    Repeater {
                        model: rootPopup._currentNetworks

                        delegate: NetworkRow {
                            required property var modelData
                            width: parent.width
                            network: modelData
                            accentColor: theme.accentActive
                            actionText: "Bağlı"
                            activePill: true
                            onActivated: {}
                        }
                    }

                    Item {
                        id: disconnectRow
                        visible: rootPopup.currentSsid.length > 0
                        width: parent.width
                        height: 30
                        property bool hovered: false
                        scale: disconnectTap.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: theme.animPress; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: disconnectRow.hovered ? Qt.rgba(0.97, 0.29, 0.29, 0.08) : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Bağlantıyı Kes"
                            font.pixelSize: 11
                            color: disconnectRow.hovered ? theme.danger : Qt.rgba(1, 1, 1, 0.72)
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            font.pixelSize: 12
                            color: Qt.rgba(1, 1, 1, 0.34)
                        }

                        HoverHandler { onHoveredChanged: disconnectRow.hovered = hovered }
                        TapHandler {
                            id: disconnectTap
                            onTapped: {
                                if (disconnectProc.running) return
                                disconnectProc.running = true
                            }
                        }
                    }
                }

                Text {
                    visible: rootPopup.wifiEnabled && rootPopup._availableNetworks.length > 0
                    text: rootPopup._currentNetworks.length > 0 ? "Mevcut Ağlar" : "Ağlar"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.42)
                    Layout.topMargin: rootPopup._currentNetworks.length > 0 ? 2 : 0
                }

                Flickable {
                    id: networkFlick
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(netList.implicitHeight, 220)
                    contentHeight: netList.implicitHeight
                    clip: true
                    interactive: true
                    visible: rootPopup.wifiEnabled && rootPopup._availableNetworks.length > 0
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: netList
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: rootPopup._availableNetworks

                            delegate: NetworkRow {
                                required property var modelData
                                width: parent.width
                                network: modelData
                                accentColor: theme.accentActive
                                actionText: modelData && modelData.secure ? "Katıl" : "Bağlan"
                                onActivated: rootPopup.connectNetwork(modelData)
                            }
                        }
                    }

                    Rectangle {
                        id: scrollTrack
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 1
                        width: 5
                        radius: 2.5
                        color: Qt.rgba(1, 1, 1, 0.05)
                        visible: networkFlick.contentHeight > networkFlick.height
                        opacity: networkFlick.moving ? 1.0 : 0.25

                        Behavior on opacity {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            height: Math.max(12, networkFlick.visibleArea.heightRatio * networkFlick.height)
                            radius: 2.5
                            y: networkFlick.visibleArea.yPosition * (networkFlick.height - height)
                            color: networkFlick.moving
                                     ? Qt.rgba(1, 1, 1, 0.45)
                                     : Qt.rgba(1, 1, 1, 0.20)

                            Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                }

                Text {
                    visible: rootPopup.wifiEnabled && rootPopup.networks.length === 0
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: rootPopup.scanning ? "Ağlar aranıyor…" : "Ağ bulunamadı"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.38)
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                Rectangle {
                    visible: rootPopup.wifiEnabled
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Layout.topMargin: 4
                }

                Item {
                    id: scanRow
                    visible: rootPopup.wifiEnabled
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4
                    height: 30
                    property bool hovered: false
                    scale: scanRowTap.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: theme.animPress; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: scanRow.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: rootPopup.scanning ? "Taranıyor…" : "Ağ Tara"
                        font.pixelSize: 11
                        color: scanRow.hovered ? theme.accentActive : Qt.rgba(1, 1, 1, 0.72)
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: rootPopup.scanning ? "◉" : "›"
                        font.pixelSize: 12
                        color: Qt.rgba(1, 1, 1, 0.34)
                    }

                    HoverHandler { onHoveredChanged: scanRow.hovered = hovered }
                    TapHandler {
                        id: scanRowTap

                        onTapped: rootPopup.rescan()
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                z: 5
                radius: container.glassRadius
                clip: true
                color: Qt.rgba(0.02, 0.02, 0.03, 0.56)
                opacity: connectDialog.visibleState ? 1.0 : 0.0
                visible: connectDialog.visibleState || opacity > 0.001

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.visible
                    onPressed: mouse.accepted = true
                }
            }

            WifiConnectDialog {
                id: connectDialog
                anchors.fill: parent
                z: 10
                onConnected: function(ssid) {
                    rootPopup.currentSsid = ssid
                    rootPopup.refreshCurrent()
                    rootPopup.rescan()
                }
                onFailed: function(error) {
                    rootPopup.refreshCurrent()
                    rootPopup.rescan()
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 15
                enabled: connectDialog.closing
                onPressed: mouse.accepted = true
            }
        }

    }
}
