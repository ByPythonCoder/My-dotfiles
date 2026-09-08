import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    required property string label
    property bool active: false
    property string icon: ""
    property bool hovered: false
    property bool pressed: false

    signal toggled()

    width: 80; height: 54
    scale: root.pressed ? 0.94 : 1.0
    opacity: root.active ? 1.0 : (root.hovered ? 0.9 : 0.7)

    Behavior on scale { NumberAnimation { duration: theme.animPress; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: theme.animFast } }

    Theme { id: theme }

    Rectangle {
        anchors.fill: parent; radius: theme.radiusPill
        color: root.active
            ? Qt.rgba(0.09, 0.58, 0.82, 0.18)
            : (root.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.width: root.active ? 1 : 0
        border.color: root.active
            ? Qt.rgba(0.09, 0.58, 0.82, 0.35)
            : "transparent"

        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent; anchors.margins: -4
            radius: 16; color: "transparent"
            border.width: root.active ? 1 : 0
            border.color: root.active
                ? Qt.rgba(0.09, 0.58, 0.82, 0.10)
                : "transparent"
            opacity: root.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: theme.animMed } }
        }

            Rectangle {
            anchors.top: parent.top; anchors.right: parent.right
            anchors.topMargin: 5; anchors.rightMargin: 5
            width: 4; height: 4; radius: 2
            color: root.active ? theme.archCyan : Qt.rgba(1, 1, 1, 0.10)
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent; spacing: 3

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.pixelSize: 17
            color: root.active ? theme.archCyan : Qt.rgba(1, 1, 1, 0.35)
            Behavior on color { ColorAnimation { duration: theme.animFast } }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            font.pixelSize: 10; font.weight: Font.Medium
            color: root.active ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.30)
            Behavior on color { ColorAnimation { duration: theme.animFast } }
        }
    }

    HoverHandler { onHoveredChanged: root.hovered = hovered }
    TapHandler {
        onPressedChanged: root.pressed = pressed
        onTapped: root.toggled()
    }
}
