import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon: ""
    property string text: ""
    property bool active: false
    property bool hovered: false
    property bool pressed: false

    signal clicked()

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 34
    scale: root.pressed ? 0.94 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.active
               ? Qt.rgba(0.68, 0.64, 0.86, 0.15)
               : (root.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.icon.length > 0
            text: root.icon
            font.pixelSize: 12
            color: root.active
                   ? theme.archCyan
                   : (root.hovered ? Qt.rgba(1, 1, 1, 0.70) : Qt.rgba(1, 1, 1, 0.45))
        }

        Text {
            visible: root.text.length > 0
            text: root.text
            font.pixelSize: 11
            font.weight: Font.Medium
            color: root.active
                   ? theme.archCyan
                   : (root.hovered ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(1, 1, 1, 0.55))
        }
    }

    HoverHandler { onHoveredChanged: root.hovered = hovered }

    TapHandler {
        onPressedChanged: root.pressed = pressed
        onTapped: root.clicked()
    }
}
