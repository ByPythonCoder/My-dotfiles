import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    required property var device
    property bool active: false
    property string accentColor: theme.archCyan

    signal activated()

    property bool hovered: false
    property bool pressed: false

    width: parent ? parent.width : 260
    height: 48
    scale: pressed ? 0.988 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.active
               ? Qt.rgba(0.68, 0.64, 0.86, 0.10)
               : (root.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.width: root.active ? 1 : 0
        border.color: root.active ? Qt.rgba(0.68, 0.64, 0.86, 0.25) : "transparent"

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
            text: root.active ? "\u25CF" : "\u25CB"
            font.pixelSize: 16
            color: root.active ? root.accentColor : Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: device ? device.description : "Bilinmeyen"
            font.pixelSize: 11
            font.weight: root.active ? Font.DemiBold : Font.Medium
            color: root.active ? Qt.rgba(1, 1, 1, 0.94) : Qt.rgba(1, 1, 1, 0.78)
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            visible: root.active
            radius: 6
            color: Qt.rgba(0.68, 0.64, 0.86, 0.18)
            border.width: 0.5
            border.color: Qt.rgba(0.68, 0.64, 0.86, 0.30)
            implicitWidth: activeLabel.implicitWidth + 10
            implicitHeight: 18
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: activeLabel
                anchors.centerIn: parent
                text: "Varsayılan"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: root.accentColor
            }
        }
    }

    HoverHandler { onHoveredChanged: root.hovered = hovered }

    TapHandler {
        onPressedChanged: root.pressed = pressed
        onTapped: root.activated()
    }
}
