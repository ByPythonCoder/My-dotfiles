import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

Item {

    id: sp
    required property string label
    required property string value
    required property real   barFrac
    required property color  barCol
    required property bool   hov
    signal clicked()

    Theme { id: theme }
    implicitHeight: theme.barHeight
    implicitWidth:  bg.implicitWidth

    Rectangle {
        id: bg
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: row.implicitWidth + theme.pillPaddingH * 2
        height: 26; radius: theme.pillRadius
        color:        sp.hov ? theme.bgHover   : theme.bgSurface
        border.width: 0.5
        border.color: sp.hov ? theme.borderHover : theme.border
        Behavior on color        { ColorAnimation { duration: theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: theme.animFast } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: theme.pillPaddingH
            spacing: 5

            Text {
                text: sp.label; font.family: theme.fontFamily; font.pixelSize: 10
                color: sp.barCol; anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: theme.animMed } }
            }
            Item {
                width: theme.miniBarWidth; height: theme.miniBarHeight
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { anchors.fill: parent; radius: theme.miniBarRadius; color: Qt.rgba(1,1,1,0.07) }
                Rectangle {
                    height: parent.height; width: parent.width * sp.barFrac
                    radius: theme.miniBarRadius; color: sp.barCol
                    Behavior on width { NumberAnimation { duration: theme.animSlow; easing.type: Easing.InOutSine } }
                    Behavior on color { ColorAnimation  { duration: theme.animMed } }
                }
            }
            Text {
                id: valTxt; text: sp.value
                font.family: theme.fontFamily; font.pixelSize: theme.fontBase; font.weight: Font.Medium
                color: theme.textPrimary; anchors.verticalCenter: parent.verticalCenter
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: valTxt; property: "opacity"; to: 0.3; duration: 60 }
                        PropertyAction {}
                        NumberAnimation { target: valTxt; property: "opacity"; to: 1.0; duration: 100 }
                    }
                }
            }
        }
    }
    HoverHandler {}
    TapHandler { onTapped: sp.clicked() }
}
