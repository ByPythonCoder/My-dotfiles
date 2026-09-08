import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../osd"

Item {
    id: root
    Theme { id: theme }

    property var popupManager: null

    implicitWidth:  col.implicitWidth + 20
    implicitHeight: theme.barHeight

    property int  dateFormat: 0

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Timer {
        id: secTimer; interval: 1000; running: true; repeat: true
        onTriggered: secDot.opacity = secDot.opacity > 0.5 ? 0.15 : 1.0
    }

    readonly property string timeStr: {
        var d = clock.date
        return String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0")
    }

    readonly property string dateStr: {
        var d    = clock.date
        var days = ["Paz","Pzt","Sal","Çar","Per","Cum","Cmt"]
        var mons = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]
        if (root.dateFormat === 0)
            return days[d.getDay()] + " " + d.getDate() + " " + mons[d.getMonth()]
        else if (root.dateFormat === 1)
            return d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,"0") + "-" + String(d.getDate()).padStart(2,"0")
        else
            return String(d.getDate()).padStart(2,"0") + "/" + String(d.getMonth()+1).padStart(2,"0") + "/" + String(d.getFullYear()).slice(-2)
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 1

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Text {
                id: timeLbl; text: root.timeStr
                font.family: theme.fontFamily; font.pixelSize: theme.fontLg; font.weight: Font.Medium
                color: theme.textPrimary
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: timeLbl; property: "opacity"; to: 0.0; duration: 80 }
                        PropertyAction {}
                        NumberAnimation { target: timeLbl; property: "opacity"; to: 1.0; duration: 150 }
                    }
                }
            }
            Rectangle {
                id: secDot; width: 3; height: 3; radius: 1.5; color: theme.archCyan
                anchors.verticalCenter: timeLbl.verticalCenter; anchors.verticalCenterOffset: 2
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
            }
        }

        Text {
            id: dateLbl
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateStr
            font.family: theme.fontFamily; font.pixelSize: theme.fontSm
            color: hov.hovered ? theme.textPrimary : theme.textMuted
            font.letterSpacing: 0.6
            Behavior on color { ColorAnimation { duration: theme.animFast } }
        }
    }

    HoverHandler { id: hov }

    TapHandler {
        onTapped: { if (popupManager) popupManager.toggleMajor("calendar") }
        onLongPressed: root.dateFormat = (root.dateFormat + 1) % 3
    }

    CalendarOSD {
        id: cal
        targetItem: col
    }

    property var calPopup: cal
}
