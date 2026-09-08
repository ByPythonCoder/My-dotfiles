import QtQuick
import ".."

Item {
    id: root

    property alias glassRadius: bg.radius
    property alias glassColor: bg.color
    property alias glassBorder: borderRect.border.color
    property alias glassBorderWidth: borderRect.border.width
    default property alias content: contentSlot.data

    Theme { id: theme }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: theme.panelBg
        radius: theme.radiusPanel
    }

    Rectangle {
        id: contentSlot
        anchors.fill: parent
        color: "transparent"
        radius: bg.radius
        clip: true
    }

    Rectangle {
        id: borderRect
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: theme.panelBorder
        radius: bg.radius
    }
}
