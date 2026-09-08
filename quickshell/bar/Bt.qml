import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import ".."
import "../osd"
import "../popups"

Item {
    id: root

    property var popupManager: null
    property bool powered: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    property string adapterName: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.name : ""
    property bool connected: false
    property string connectedDeviceName: ""
    property int batteryPct: -1
    property bool batteryAvailable: false
    property bool hovered: false
    property bool _prevPowered: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    property bool _suppressConnectionOsd: false

    readonly property string displayText: {
        if (!powered) return "Kapalı"
        if (connected) {
            var n = connectedDeviceName || "Cihaz"
            return n.length <= 12 ? n : n.substring(0, 11) + "…"
        }
        return "Açık"
    }

    function refreshDevices() {
        var devs = Bluetooth.devices
        if (!devs)
            return

        var foundConnected = false
        var devName = ""
        var devBattery = -1
        var devBattAvail = false

        var n = devs.count !== undefined ? devs.count : 0
        for (var i = 0; i < n; ++i) {
            var d = devs.get(i)
            if (d && d.connected) {
                foundConnected = true
                devName = d.deviceName || d.name || "Bluetooth"
                devBattery = d.batteryAvailable && typeof d.battery === "number" && isFinite(d.battery)
                           ? Math.max(0, Math.min(100, Math.round(d.battery)))
                           : -1
                devBattAvail = d.batteryAvailable || false
                break
            }
        }

        var oldConnected = root.connected
        var oldName = root.connectedDeviceName

        root.connected = foundConnected
        root.connectedDeviceName = devName
        root.batteryPct = devBattery
        root.batteryAvailable = devBattAvail

        if (!root._suppressConnectionOsd
                && (foundConnected !== oldConnected || (foundConnected && devName !== oldName))) {
            btOsd.mode = "connection"
            btOsd.deviceName = (devName && devName.length > 0) ? devName : "Bluetooth"
            btOsd.connected = foundConnected
            btOsd.batteryPct = devBattAvail ? devBattery : -1
            if (popupManager) popupManager.showOsd("bluetooth")
        }
    }

    function togglePopup() {
        if (popupManager)
            popupManager.toggleMajor("bluetooth")
    }

    implicitWidth: pillBg.implicitWidth
    implicitHeight: theme.barHeight

    onPoweredChanged: {
        if (powered !== _prevPowered) {
            _suppressConnectionOsd = true
            powerDebounce.restart()
            btOsd.mode = "power"
            btOsd.deviceName = "Bluetooth"
            btOsd.connected = powered
            btOsd.batteryPct = -1
            if (popupManager) popupManager.showOsd("bluetooth")
            _prevPowered = powered
        }
    }

    Component.onCompleted: refreshDevices()

    Theme { id: theme }

    Timer {
        id: powerDebounce
        interval: 500
        repeat: false
        onTriggered: root._suppressConnectionOsd = false
    }

    Repeater {
        model: Bluetooth.devices

        delegate: Item {
            visible: false
            width: 0
            height: 0

            required property var modelData

            Connections {
                target: modelData
                ignoreUnknownSignals: true
                function onConnectedChanged() { root.refreshDevices() }
                function onBatteryChanged() { root.refreshDevices() }
                function onDeviceNameChanged() { root.refreshDevices() }
                function onNameChanged() { root.refreshDevices() }
                function onBatteryAvailableChanged() { root.refreshDevices() }
            }
        }
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
            spacing: 5

            Text {
                text: "BT"
                font.family: theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: root.connected ? theme.archCyan : (root.powered ? theme.textMuted : theme.textDim)

                Behavior on color {
                    ColorAnimation { duration: theme.animMed }
                }
            }

            Text {
                text: root.displayText
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSm
                color: root.connected ? theme.textPrimary : (root.powered ? theme.textMuted : theme.textDim)

                Behavior on color {
                    ColorAnimation { duration: theme.animMed }
                }
            }

            Item {
                width: root.connected && root.batteryAvailable && root.batteryPct >= 0 ? theme.miniBarWidth : 0
                height: theme.miniBarHeight
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: theme.miniBarRadius
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.min(1, Math.max(0, root.batteryPct / 100))
                    radius: theme.miniBarRadius
                    color: theme.batteryColor(root.batteryPct)

                    Behavior on width {
                        NumberAnimation {
                            duration: theme.animMed
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: theme.animMed
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Behavior on color {
            ColorAnimation { duration: theme.animFast }
        }

        Behavior on border.color {
            ColorAnimation { duration: theme.animFast }
        }
    }

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.togglePopup()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.togglePopup()
    }

    BtOSD {
        id: btOsd
        targetItem: pillBg
    }

    BtDevicePopup {
        id: devicePopup
        targetItem: pillBg
    }

    property var btPopup: devicePopup
    property var osdPopup: btOsd
}
