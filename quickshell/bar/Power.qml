import Quickshell
import QtQuick
import ".."
import "../popups"

Item {
    id: root

    Theme { id: theme }

    property var popupManager: null
    property bool hovered: false

    readonly property var powerPopup: powerMenu

    implicitWidth: pillBg.implicitWidth
    implicitHeight: theme.barHeight

    function togglePopup() {
        if (popupManager)
            popupManager.toggleMajor("power")
    }

    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: row.implicitWidth + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius

        color: root.hovered ? theme.bgHover : theme.bgSurface
        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on color { ColorAnimation { duration: theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: theme.animFast } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Text {
                text: "\uf011"
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.45)
            }
        }
    }

    HoverHandler {
        onHoveredChanged: root.hovered = hovered
    }

    TapHandler {
        onTapped: root.togglePopup()
    }

    PowerMenu {
        id: powerMenu
        targetItem: pillBg
    }
}
