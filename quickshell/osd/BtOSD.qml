import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "."

PopupWindow {
    id: osdWindow

    property var targetItem: null
    color: "transparent"

    anchor {
        item: osdWindow.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
    }

    implicitWidth: 320
    implicitHeight: 140
    visible: osdVisible || contentContainer.opacity > 0.001

    property bool osdVisible: false
    property string deviceName: "Bluetooth"
    property bool connected: false
    property string mode: ""
    property int batteryPct: -1

    Timer {
        id: dismissTimer
        interval: 1700
        repeat: false
        onTriggered: osdWindow.close()
    }

    function open() {
        osdWindow.osdVisible = true
        dismissTimer.restart()
    }

    function close() {
        osdWindow.osdVisible = false
        dismissTimer.stop()
    }

    function show(mode, name, connected, battery) {
        osdWindow.mode = mode
        osdWindow.deviceName = (name && name.length > 0) ? name : "Bluetooth"
        osdWindow.connected = connected
        osdWindow.batteryPct = battery === undefined ? -1 : battery
        open()
    }

    readonly property bool showBattery: connected && batteryPct >= 0

    readonly property string titleText: {
        if (mode === "power")
            return "Bluetooth"
        return deviceName
    }

    readonly property string statusText: {
        if (mode === "power")
            return connected ? "Açık" : "Kapalı"
        if (mode === "connection")
            return connected ? "Bağlı" : "Bağlantı Kesildi"
        return connected ? "Bağlı" : "Kapalı"
    }

    readonly property string subText: {
        if (showBattery)
            return "Pil " + batteryPct + "%"
        return ""
    }

    readonly property string iconText: connected ? "󰂱" : "󰂲"

    readonly property real fillAmount: {
        if (showBattery)
            return Math.min(1.0, Math.max(0.0, batteryPct / 100))
        return connected ? 1.0 : 0.0
    }

    Rectangle {
        id: contentContainer
        width: 280
        height: subText.length > 0 ? 74 : 64
        radius: 14
        color: Qt.rgba(0.06, 0.07, 0.09, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale: osdWindow.osdVisible ? 1.0 : 0.93
        y: osdWindow.osdVisible ? 14 : -40

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: osdWindow.titleText
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.45)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: osdWindow.statusText
                    font.pixelSize: 11
                    font.bold: true
                    color: osdWindow.connected ? theme.accentActive : Qt.rgba(1, 1, 1, 0.4)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: osdWindow.iconText
                    font.pixelSize: 14
                    color: osdWindow.connected ? theme.accentActive : Qt.rgba(1, 1, 1, 0.65)
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 5
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        width: parent.width * osdWindow.fillAmount
                        height: parent.height
                        radius: 3
                        color: osdWindow.connected ? theme.accentActive : Qt.rgba(1, 1, 1, 0.20)

                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Text {
                visible: osdWindow.subText.length > 0
                text: osdWindow.subText
                font.pixelSize: 10
                color: Qt.rgba(1, 1, 1, 0.42)
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
