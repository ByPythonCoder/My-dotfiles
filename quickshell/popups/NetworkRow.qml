import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var network
    property string accentColor: "#8be9ff"
    property string actionText: "Bağlan"
    property bool activePill: false
    signal activated()

    property bool hovered: false
    property bool pressed: false

    width: parent ? parent.width : 260
    height: 52
    scale: pressed ? 0.988 : 1.0

    function safeText(v, fallback) {
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : fallback
    }

    function safeInt(v, fallback) {
        var n = parseInt(v, 10)
        return isNaN(n) ? fallback : n
    }

    function signalBars(pct) {
        pct = safeInt(pct, 0)
        if (pct >= 80) return 4
        if (pct >= 55) return 3
        if (pct >= 30) return 2
        if (pct > 0) return 1
        return 0
    }

    readonly property string ssidText: safeText(network && network.ssid, "Gizli Ağ")
    readonly property string securityText: safeText(network && network.security, "Açık")
    readonly property int signalTextValue: safeInt(network && network.signal, 0)
    readonly property bool activeState: !!(network && network.active)
    readonly property bool secureState: !!(network && network.secure)

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: root.activeState
               ? Qt.rgba(1, 1, 1, 0.075)
               : (root.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.width: root.activeState ? 1 : 0
        border.color: root.activeState ? Qt.rgba(1, 1, 1, 0.07) : "transparent"

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Item {
            width: 13
            height: 13
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: 4
                Rectangle {
                    property int barH: [4, 6, 9, 13][index]
                    property bool lit: root.signalBars(root.signalTextValue) > index
                    width: 2.5
                    height: barH
                    radius: 1.2
                    x: index * 3.5
                    y: 13 - barH
                    color: lit ? root.accentColor : Qt.rgba(1, 1, 1, 0.16)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.ssidText
                font.pixelSize: 11
                font.weight: root.activeState ? Font.DemiBold : Font.Medium
                color: Qt.rgba(1, 1, 1, root.activeState ? 0.94 : 0.80)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.securityText + " · " + root.signalTextValue + "%"
                font.pixelSize: 10
                color: root.activeState ? Qt.rgba(1, 1, 1, 0.46) : Qt.rgba(1, 1, 1, 0.36)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Rectangle {
            visible: root.activeState && root.activePill
            radius: 8
            color: Qt.rgba(0.20, 0.78, 0.42, 0.18)
            border.width: 1
            border.color: Qt.rgba(0.20, 0.78, 0.42, 0.28)
            implicitWidth: connectedText.implicitWidth + 12
            implicitHeight: 22
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: connectedText
                anchors.centerIn: parent
                text: root.safeText(root.actionText, "Bağlı")
                font.pixelSize: 10
                font.weight: Font.Medium
                color: "#7dffb0"
            }
        }

        Text {
            visible: !root.activeState
            text: root.safeText(root.actionText, "Bağlan")
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.hovered ? root.accentColor : Qt.rgba(1, 1, 1, 0.40)

            Behavior on color {
                ColorAnimation { duration: 140 }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    TapHandler {
        onPressedChanged: root.pressed = pressed
        onTapped: root.activated()
    }
}
