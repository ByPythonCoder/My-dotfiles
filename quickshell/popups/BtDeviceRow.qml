import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var device
    property string accentColor: theme.accentActive
    property string actionText: device && device.connected ? "Bağlantıyı Kes" : "Bağlan"
    property string subtitleText: ""

    // inline feedback from BtDevicePopup (no modal needed)
    property bool busy: false
    property string busyLabel: "Çalışıyor…"
    property bool failed: false
    property string failedLabel: "Başarısız"

    signal activated()

    property bool hovered: false
    property bool pressed: false

    // matches NetworkRow.qml height
    width: parent ? parent.width : 260
    height: 52
    scale: pressed ? 0.988 : 1.0
    opacity: busy ? 0.7 : 1.0

    function label() {
        if (!device) return "Bilinmeyen Cihaz"
        if (device.deviceName !== undefined && device.deviceName !== null && String(device.deviceName).trim().length > 0)
            return String(device.deviceName).trim()
        if (device.name !== undefined && device.name !== null && String(device.name).trim().length > 0)
            return String(device.name).trim()
        return "Bilinmeyen Cihaz"
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: root.device && root.device.connected
               ? Qt.rgba(1, 1, 1, 0.075)
               : (root.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.width: root.device && root.device.connected ? 1 : 0
        border.color: root.device && root.device.connected ? Qt.rgba(0, 240 / 255, 1, 0.14) : "transparent"

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
            text: root.device && root.device.connected ? "󰂱" : "󰂲"
            font.pixelSize: 14
            color: root.device && root.device.connected ? root.accentColor : Qt.rgba(1, 1, 1, 0.64)
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.label()
                font.pixelSize: 11
                font.weight: root.device && root.device.connected ? Font.DemiBold : Font.Medium
                color: root.device && root.device.connected ? Qt.rgba(1, 1, 1, 0.94) : Qt.rgba(1, 1, 1, 0.80)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: subtitleText !== "" && !root.failed
                text: subtitleText
                font.pixelSize: 10
                color: root.device && root.device.connected ? root.accentColor : Qt.rgba(1, 1, 1, 0.36)
                opacity: visible ? 1.0 : 0.0
                elide: Text.ElideRight
                Layout.fillWidth: true

                Behavior on opacity {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            text: root.failed ? root.failedLabel : (root.busy ? root.busyLabel : root.actionText)
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.failed
                   ? Qt.rgba(1.0, 0.45, 0.45, 0.95)
                   : (root.busy
                      ? Qt.rgba(1, 1, 1, 0.45)
                      : (root.hovered ? root.accentColor : Qt.rgba(1, 1, 1, 0.40)))

            Behavior on color {
                ColorAnimation { duration: 140 }
            }
        }
    }

    HoverHandler { onHoveredChanged: root.hovered = hovered }

    TapHandler {
        enabled: !root.busy
        onPressedChanged: root.pressed = pressed
        onTapped: root.activated()
    }
}
