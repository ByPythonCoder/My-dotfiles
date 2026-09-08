import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "."
import ".."
import "../components"

PopupWindow {
    id: rootPopup

    property var targetItem: null
    property bool visibleState: false

    property string busyKey: ""
    property string busyAction: ""
    property string failedKey: ""
    property string failedDetail: ""
    property bool scanning: false

    // plain data, populated via bluetoothctl (Quickshell.Bluetooth was
    // unreliable for devices connected via CLI)
    property var connectedDevices: []
    property var scannedDevices: []

    readonly property int myCount: connectedDevices ? connectedDevices.length : 0
    readonly property int nearbyCount: scannedDevices ? scannedDevices.length : 0

    function safeText(v, fallback) {
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : fallback
    }

    function deviceKey(d) {
        if (!d) return ""
        return safeText(d.address, safeText(d.deviceName, safeText(d.name, "")))
    }

    function hasBattery(d) {
        return d && d.batteryAvailable
               && typeof d.battery === "number"
               && isFinite(d.battery)
               && d.battery >= 0
    }

    function batteryText(d) {
        return hasBattery(d) ? Math.round(d.battery) + "%" : ""
    }

    function prettyFallbackName(mac) {
        if (!mac) return "Unknown Device"
        var parts = mac.split(":")
        var tail = parts.length >= 3 ? parts.slice(-3).join(":") : mac
        return "Device " + tail
    }

    // preference: Alias > Name > scanned text > MAC-derived fallback
    function resolveDisplayName(mac, alias, name, scannedText) {
        var a = (alias || "").trim()
        if (a.length > 0) return a

        var n = (name || "").trim()
        if (n.length > 0) return n

        var s = (scannedText || "").trim()
        if (s.length > 0 && s.toUpperCase() !== mac.toUpperCase()) return s

        return prettyFallbackName(mac)
    }

    function open() {
        visibleState = true
        refreshConnected()
        if (anchor && anchor.updateAnchor)
            anchor.updateAnchor()
    }

    function close() {
        visibleState = false
    }

    function refreshConnected() {
        connectedListProc.running = true
    }

    function startScan() {
        if (scanProc.running)
            return
        scanProc.running = true
    }

    function stopScan() {
        if (scanProc.running)
            scanProc.running = false
    }

    function toggleScan() {
        if (scanning)
            stopScan()
        else
            startScan()
    }

    function beginAction(d, action) {
        busyKey = deviceKey(d)
        busyAction = action
        failedKey = ""
        failedDetail = ""
        busyTimeoutTimer.restart()
    }

    function clearBusy() {
        busyKey = ""
        busyAction = ""
        failedDetail = ""
        busyTimeoutTimer.stop()
    }

    function connectDevice(d) {
        if (!d)
            return
        beginAction(d, "connect")
        pairAndConnectProc.mac = d.address
        pairAndConnectProc.deviceName = d.deviceName || d.name || d.address

        // Already-bonded devices must NOT be re-paired: bluetoothctl pair on a
        // paired AirPods-style device forces a re-pair that times out and
        // leaves the device unable to connect. Only pair when we know it isn't.
        var chain = ""
        if (d.paired === true) {
            chain = "stdbuf -oL -eL bluetoothctl trust " + d.address +
                    "; stdbuf -oL -eL bluetoothctl connect " + d.address
        } else {
            chain = "stdbuf -oL -eL bluetoothctl pairable on" +
                    "; stdbuf -oL -eL bluetoothctl pair " + d.address +
                    "; stdbuf -oL -eL bluetoothctl trust " + d.address +
                    "; stdbuf -oL -eL bluetoothctl connect " + d.address
        }

        pairAndConnectProc.command = ["sh", "-c", chain]
        pairAndConnectProc.running = true
    }

    function disconnectDevice(d) {
        if (!d)
            return
        beginAction(d, "disconnect")
        disconnectProc.mac = d.address
        disconnectProc.running = true
    }

    color: "transparent"
    implicitWidth: 340
    implicitHeight: 440
    visible: visibleState || container.opacity > 0.001

    anchor {
        item: rootPopup.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
        margins.top: 10
    }

    // poll connected-device state via bluetoothctl
    Timer {
        interval: 4000
        running: rootPopup.visibleState
        repeat: true
        triggeredOnStart: false
        onTriggered: rootPopup.refreshConnected()
    }

    Timer {
        id: busyTimeoutTimer
        interval: 40000
        repeat: false
        onTriggered: {
            rootPopup.failedKey = rootPopup.busyKey
            rootPopup.busyKey = ""
            rootPopup.busyAction = ""
            if (rootPopup.failedDetail === "")
                rootPopup.failedDetail = "Zaman aşımı"
            failedClearTimer.restart()
        }
    }

    Timer {
        id: failedClearTimer
        interval: 2500
        repeat: false
        onTriggered: rootPopup.failedKey = ""
    }

    // connected-devices poll step 1: list MACs
    Process {
        id: connectedListProc
        command: ["sh", "-c", "stdbuf -oL -eL bluetoothctl devices Connected"]
        property var rawLines: []

        stdout: SplitParser {
            onRead: line => connectedListProc.rawLines.push(line)
        }

        onStarted: rawLines = []

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var macs = []
            var names = {}

            for (var i = 0; i < rawLines.length; ++i) {
                var clean = rawLines[i].replace(/\x1b\[[0-9;]*m/g, "")
                var m = clean.match(/Device\s+([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})\s*(.*)$/)
                if (!m)
                    continue
                var mac = m[1].toUpperCase()
                macs.push(mac)
                names[mac] = (m[2] || "").trim()
            }

            if (macs.length === 0) {
                rootPopup.connectedDevices = []
                return
            }

            var script = macs.map(function(mac) {
                return "echo @@" + mac + "; bluetoothctl info " + mac
            }).join("; ")

            infoProc.macs = macs
            infoProc.names = names
            infoProc.command = ["sh", "-c", "stdbuf -oL -eL sh -c \"" + script.replace(/"/g, "\\\"") + "\""]
            infoProc.running = true
        }
    }

    // step 2: resolve Alias/Name/battery per device
    Process {
        id: infoProc
        property var macs: []
        property var names: ({})
        property var rawLines: []
        command: []
        running: false

        stdout: SplitParser {
            onRead: line => infoProc.rawLines.push(line)
        }

        onStarted: rawLines = []

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var blocks = {}
            var currentMac = ""

            for (var i = 0; i < rawLines.length; ++i) {
                var line = rawLines[i]
                var marker = line.match(/^@@([0-9A-Fa-f:]+)/)
                if (marker) {
                    currentMac = marker[1].toUpperCase()
                    blocks[currentMac] = []
                    continue
                }
                if (currentMac.length > 0 && blocks[currentMac])
                    blocks[currentMac].push(line)
            }

            var result = []
            for (var j = 0; j < infoProc.macs.length; ++j) {
                var mac = infoProc.macs[j]
                var block = blocks[mac] || []
                var battery = -1
                var alias = ""
                var name = ""
                var paired = false

                for (var k = 0; k < block.length; ++k) {
                    var trimmedLine = block[k].trim()

                    var bm = trimmedLine.match(/Battery Percentage:.*\((\d+)\)/)
                    if (bm)
                        battery = parseInt(bm[1], 10)

                    var am = trimmedLine.match(/^Alias:\s*(.*)$/)
                    if (am && am[1].trim().length > 0)
                        alias = am[1].trim()

                    var nm = trimmedLine.match(/^Name:\s*(.*)$/)
                    if (nm && nm[1].trim().length > 0)
                        name = nm[1].trim()

                    var pm = trimmedLine.match(/^Paired:\s*(yes|no)/i)
                    if (pm)
                        paired = pm[1].toLowerCase() === "yes"
                }

                var scannedText = infoProc.names[mac] || ""
                var displayName = rootPopup.resolveDisplayName(mac, alias, name, scannedText)

                result.push({
                    address: mac,
                    deviceName: displayName,
                    connected: true,
                    paired: paired,
                    batteryAvailable: battery >= 0,
                    battery: battery
                })
            }

            result.sort(function(a, b) { return a.deviceName.localeCompare(b.deviceName) })
            rootPopup.connectedDevices = result
        }
    }

    // live bluetoothctl scan — uses stdin pipe because bare arg exits
    Process {
        id: scanProc
        command: ["sh", "-c", "{ echo 'scan on'; sleep 8; echo 'scan off'; echo quit; } | stdbuf -oL -eL bluetoothctl"]
        property var rawLines: []

        stdout: SplitParser {
            onRead: line => scanProc.rawLines.push(line)
        }

        onRunningChanged: rootPopup.scanning = running

        onStarted: rawLines = []

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var seen = {}
            var order = []

            for (var i = 0; i < rawLines.length; ++i) {
                var clean = rawLines[i].replace(/\x1b\[[0-9;]*m/g, "")
                var m = clean.match(/Device\s+([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})\s*(.*)$/)
                if (!m)
                    continue

                var mac = m[1].toUpperCase()
                var scannedText = (m[2] || "").trim()

                if (!(mac in seen)) {
                    seen[mac] = scannedText
                    order.push(mac)
                } else if (scannedText.length > 0) {
                    seen[mac] = scannedText
                }
            }

            var connectedMacs = {}
            for (var j = 0; j < rootPopup.connectedDevices.length; ++j) {
                var cd = rootPopup.connectedDevices[j]
                if (cd && cd.address)
                    connectedMacs[cd.address] = true
            }

            var newMacs = order.filter(function(mac) { return !(mac in connectedMacs) })

            if (newMacs.length === 0) {
                rootPopup.scannedDevices = []
                return
            }

            // show provisional entries while names resolve
            var provisional = newMacs.map(function(mac) {
                return {
                    address: mac,
                    deviceName: rootPopup.resolveDisplayName(mac, "", "", seen[mac]),
                    connected: false,
                    batteryAvailable: false,
                    battery: -1
                }
            })
            rootPopup.scannedDevices = provisional

            var script = newMacs.map(function(mac) {
                return "echo @@" + mac + "; bluetoothctl info " + mac
            }).join("; ")

            scanInfoProc.macs = newMacs
            scanInfoProc.scannedNames = seen
            scanInfoProc.command = ["sh", "-c", "stdbuf -oL -eL sh -c \"" + script.replace(/"/g, "\\\"") + "\""]
            scanInfoProc.running = true
        }
    }

    // resolve names for scanned (non-connected) devices
    Process {
        id: scanInfoProc
        property var macs: []
        property var scannedNames: ({})
        property var rawLines: []
        command: []
        running: false

        stdout: SplitParser {
            onRead: line => scanInfoProc.rawLines.push(line)
        }

        onStarted: rawLines = []

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var blocks = {}
            var currentMac = ""

            for (var i = 0; i < rawLines.length; ++i) {
                var line = rawLines[i]
                var marker = line.match(/^@@([0-9A-Fa-f:]+)/)
                if (marker) {
                    currentMac = marker[1].toUpperCase()
                    blocks[currentMac] = []
                    continue
                }
                if (currentMac.length > 0 && blocks[currentMac])
                    blocks[currentMac].push(line)
            }

            var result = []
            for (var j = 0; j < scanInfoProc.macs.length; ++j) {
                var mac = scanInfoProc.macs[j]
                var block = blocks[mac] || []
                var alias = ""
                var name = ""
                var paired = false

                for (var k = 0; k < block.length; ++k) {
                    var trimmedLine = block[k].trim()

                    var am = trimmedLine.match(/^Alias:\s*(.*)$/)
                    if (am && am[1].trim().length > 0)
                        alias = am[1].trim()

                    var nm = trimmedLine.match(/^Name:\s*(.*)$/)
                    if (nm && nm[1].trim().length > 0)
                        name = nm[1].trim()

                    var pm = trimmedLine.match(/^Paired:\s*(yes|no)/i)
                    if (pm)
                        paired = pm[1].toLowerCase() === "yes"
                }

                var scannedText = scanInfoProc.scannedNames[mac] || ""
                var displayName = rootPopup.resolveDisplayName(mac, alias, name, scannedText)

                result.push({
                    address: mac,
                    deviceName: displayName,
                    connected: false,
                    paired: paired,
                    batteryAvailable: false,
                    battery: -1
                })
            }

            result.sort(function(a, b) { return a.deviceName.localeCompare(b.deviceName) })
            rootPopup.scannedDevices = result
        }
    }

    // pair + trust + connect (fresh devices need pairing first)
    Process {
        id: pairAndConnectProc
        property string mac: ""
        property string deviceName: ""
        property string output: ""
        command: []
        running: false

        stdout: SplitParser {
            onRead: line => {
                pairAndConnectProc.output += (pairAndConnectProc.output.length > 0 ? "\n" : "") + line
            }
        }

        onStarted: output = ""

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var ok = /Connection successful/i.test(output) && !/Failed to connect/i.test(output)

            if (ok) {
                rootPopup.clearBusy()

                // promote to connected immediately; next poll fills battery
                var already = rootPopup.connectedDevices.some(function(d) { return d.address === mac })
                if (!already) {
                    var optimistic = rootPopup.connectedDevices.concat([{
                        address: mac,
                        deviceName: pairAndConnectProc.deviceName,
                        connected: true,
                        batteryAvailable: false,
                        battery: -1
                    }])
                    optimistic.sort(function(a, b) { return a.deviceName.localeCompare(b.deviceName) })
                    rootPopup.connectedDevices = optimistic
                }

                rootPopup.scannedDevices = rootPopup.scannedDevices.filter(function(r) {
                    return r.address !== mac
                })

                rootPopup.refreshConnected()
            } else {
                var err = output.match(/Failed to (pair|connect):\s*([^\n]*)/i)
                rootPopup.failedKey = mac
                rootPopup.failedDetail = err ? err[2].trim() : (output.trim() ? output.trim().split("\n").pop().trim() : "")
                rootPopup.busyKey = ""
                rootPopup.busyAction = ""
                busyTimeoutTimer.stop()
                failedClearTimer.restart()
            }
        }
    }

    Process {
        id: disconnectProc
        property string mac: ""
        property string output: ""
        command: ["sh", "-c", "stdbuf -oL -eL bluetoothctl disconnect " + mac]
        running: false

        stdout: SplitParser {
            onRead: line => {
                disconnectProc.output += (disconnectProc.output.length > 0 ? "\n" : "") + line
            }
        }

        onStarted: output = ""

        onExited: function(exitCode, exitStatus) {
            if (!rootPopup.visibleState) return
            var failed = /Failed/i.test(output)

            if (failed) {
                rootPopup.failedKey = mac
                rootPopup.busyKey = ""
                rootPopup.busyAction = ""
                busyTimeoutTimer.stop()
                failedClearTimer.restart()
            } else {
                rootPopup.clearBusy()
                rootPopup.connectedDevices = rootPopup.connectedDevices.filter(function(d) {
                    return d.address !== mac
                })
            }

            rootPopup.refreshConnected()
        }
    }

    GlassPanel {
        id: container
        width: 300
        height: Math.min(410, contentCol.implicitHeight + 18)
        glassRadius: 14
        glassColor: Qt.rgba(0.06, 0.07, 0.09, 0.85)
        glassBorder: Qt.rgba(1, 1, 1, 0.08)
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.975
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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
                        text: "Bluetooth"
                        font.pixelSize: 13
                        font.bold: true
                        color: Qt.rgba(1, 1, 1, 0.94)
                    }

                    Text {
                        text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "Açık" : "Kapalı"
                        font.pixelSize: 10
                        color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                               ? theme.accentActive
                               : Qt.rgba(1, 1, 1, 0.40)
                    }
                }

                Rectangle {
                    id: toggleTrack
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    width: 38
                    height: 20
                    radius: 10
                    color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                           ? theme.accentActive
                           : Qt.rgba(1, 1, 1, 0.10)
                    scale: toggleTap.pressed ? 0.97 : 1.0

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.95)
                        anchors.verticalCenter: parent.verticalCenter
                        x: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? 20 : 2

                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }

                    TapHandler {
                        id: toggleTap
                        onTapped: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                rootPopup.refreshConnected()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Text {
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && myCount > 0
                text: "Cihazlarım"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Qt.rgba(1, 1, 1, 0.42)
            }

            Column {
                Layout.fillWidth: true
                spacing: 4
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && myCount > 0

                move: Transition {
                    NumberAnimation { properties: "y"; duration: 240; easing.type: Easing.OutCubic }
                }
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                    NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 220; easing.type: Easing.OutBack }
                }

                Repeater {
                    model: rootPopup.connectedDevices

                    delegate: BtDeviceRow {
                        required property var modelData

                        width: parent.width
                        device: modelData
                        accentColor: theme.accentActive
                        actionText: "Bağlantıyı Kes"
                        subtitleText: "Bağlı"
                        busy: rootPopup.busyKey !== "" && rootPopup.busyKey === rootPopup.deviceKey(modelData)
                        busyLabel: rootPopup.busyAction === "connect" ? "Bağlanıyor…" : "Bağlantı Kesiliyor…"
                        failed: rootPopup.failedKey !== "" && rootPopup.failedKey === rootPopup.deviceKey(modelData)
                        failedLabel: rootPopup.failedDetail !== "" ? rootPopup.failedDetail : "Başarısız"
                        onActivated: rootPopup.disconnectDevice(modelData)
                    }
                }
            }

            Text {
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && nearbyCount > 0
                text: rootPopup.myCount > 0 ? "Yakındaki Cihazlar" : "Cihazlar"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Qt.rgba(1, 1, 1, 0.42)
                Layout.topMargin: myCount > 0 ? 2 : 0
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(nearList.implicitHeight, 220)
                contentHeight: nearList.implicitHeight
                clip: true
                interactive: true
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && nearbyCount > 0
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: nearList
                    width: parent.width
                    spacing: 4

                    move: Transition {
                      NumberAnimation { properties: "y"; duration: 240; easing.type: Easing.OutCubic }
                    }
                    add: Transition {
                      NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                      NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        model: rootPopup.scannedDevices

                        delegate: BtDeviceRow {
                            required property var modelData

                            width: parent.width
                            device: modelData
                            accentColor: theme.accentActive
                            actionText: "Bağlan"
                            subtitleText: ""
                            busy: rootPopup.busyKey !== "" && rootPopup.busyKey === rootPopup.deviceKey(modelData)
                            busyLabel: "Bağlanıyor…"
                            failed: rootPopup.failedKey !== "" && rootPopup.failedKey === rootPopup.deviceKey(modelData)
                            failedLabel: rootPopup.failedDetail !== "" ? rootPopup.failedDetail : "Başarısız"
                            onActivated: rootPopup.connectDevice(modelData)
                        }
                    }
                }
            }

            ColumnLayout {
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                         && myCount === 0
                         && nearbyCount === 0
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: rootPopup.scanning ? "Cihazlar aranıyor…" : "Cihaz bulunamadı"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.38)
                }

                Text {
                    visible: rootPopup.scanning
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Cihazın eşleşme modunda olduğundan emin olun"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.28)
                }
            }

            Rectangle {
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                Layout.topMargin: 4
            }

            Item {
                id: scanRow
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
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
                    text: rootPopup.scanning ? "Taramayı Durdur" : "Cihaz Tara"
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

                HoverHandler {
                    onHoveredChanged: scanRow.hovered = hovered
                }

                TapHandler {
                    id: scanRowTap

                    onTapped: rootPopup.toggleScan()
                }
            }
        }
    }

    Component.onCompleted: refreshConnected()
}
