import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: osdWindow

    property var targetItem: null
    property bool osdVisible: false

    color:   "transparent"
    visible: osdVisible || container.opacity > 0.001

    anchor {
        item:  osdWindow.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
    }

    implicitWidth:  240
    implicitHeight: 300

    function open()   { osdVisible = true }
    function close()  { osdVisible = false }
    function toggle() { osdVisible = !osdVisible }

    // block clicks outside the calendar panel
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => {
            var containerPoint = mapToItem(container, mouse.x, mouse.y);
            if (!container.contains(containerPoint)) {
                osdWindow.close();
            } else {
                mouse.accepted = false;
            }
        }
    }

    Rectangle {
        id: container
        width:  220
        radius: 14
        color:  Qt.rgba(0.06, 0.07, 0.09, 0.92)
        border.width: 1
        border.color: Qt.rgba(0.68, 0.64, 0.86, 0.35)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale:   osdWindow.osdVisible ? 1.0 : 0.93
        y:       osdWindow.osdVisible ? 14   : -40

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack  } }
        Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        height: innerCol.implicitHeight + 24

        Column {
            id: innerCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            property int viewYear:  new Date().getFullYear()
            property int viewMonth: new Date().getMonth()

            property int todayYear:  new Date().getFullYear()
            property int todayMonth: new Date().getMonth()
            property int todayDate:  new Date().getDate()

            property var monthNames: [
                "Ocak","Şubat","Mart","Nisan","Mayıs","Haziran",
                "Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"
            ]

            RowLayout {
                width: parent.width

                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: prevHov.hovered ? Qt.rgba(0.68,0.64,0.86,0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 14; color: "#7f849c" }
                    HoverHandler { id: prevHov }
                    TapHandler {
                        onTapped: {
                            if (innerCol.viewMonth === 0) {
                                innerCol.viewMonth = 11
                                innerCol.viewYear--
                            } else {
                                innerCol.viewMonth--
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: innerCol.monthNames[innerCol.viewMonth] + "  " + innerCol.viewYear
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: "#74c7ec"
                }

                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: nextHov.hovered ? Qt.rgba(0.68,0.64,0.86,0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 14; color: "#7f849c" }
                    HoverHandler { id: nextHov }
                    TapHandler {
                        onTapped: {
                            if (innerCol.viewMonth === 11) {
                                innerCol.viewMonth = 0
                                innerCol.viewYear++
                            } else {
                                innerCol.viewMonth++
                            }
                        }
                    }
                }
            }

            // Day-of-week headers
            Row {
                width: parent.width; spacing: 0
                Repeater {
                    model: ["Pzt","Sal","Çar","Per","Cum","Cmt","Paz"]
                    Text {
                        required property int index
                        required property var modelData
                        text: modelData
                        width: (container.width - 28) / 7
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 9
                        color: (index >= 5) ? "#cba6f7" : "#585b70"
                    }
                }
            }

            Grid {
                id: calGrid
                columns: 7
                spacing: 1
                width: parent.width

                property int year:  innerCol.viewYear
                property int month: innerCol.viewMonth

                property int firstDow: {
                    var fd = new Date(year, month, 1).getDay()
                    return (fd + 6) % 7
                }
                property int daysInMonth: new Date(year, month + 1, 0).getDate()
                property int totalCells:  firstDow + daysInMonth

                Repeater {
                    model: Math.ceil(calGrid.totalCells / 7) * 7

                    Rectangle {
                        property int  dayNum:  index - calGrid.firstDow + 1
                        property bool valid:   dayNum >= 1 && dayNum <= calGrid.daysInMonth
                        property bool isToday: valid
                                               && dayNum === innerCol.todayDate
                                               && calGrid.month === innerCol.todayMonth
                                               && calGrid.year  === innerCol.todayYear
                        property bool isWeekend: (index % 7) >= 5

                        width:  (container.width - 28) / 7
                        height: 22
                        radius: 5

                        color: isToday
                               ? Qt.rgba(0.68, 0.64, 0.86, 0.28)
                               : dayHov.hovered && valid
                                 ? Qt.rgba(1, 1, 1, 0.05)
                                 : "transparent"

                        border.width: isToday ? 0.5 : 0
                        border.color: isToday ? "#cba6f7" : "transparent"

                        Behavior on color { ColorAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text:  valid ? dayNum : ""
                            font.pixelSize: 10
                            font.weight: isToday ? Font.Medium : Font.Normal
                            color: isToday   ? "#74c7ec"
                                 : !valid    ? "transparent"
                                 : isWeekend ? "#cba6f7"
                                 :             "#cdd6f4"
                        }

                        HoverHandler { id: dayHov }
                    }
                }
            }

            Rectangle { width: parent.width; height: 0.5; color: Qt.rgba(0.68,0.64,0.86,0.2) }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                property var d: new Date()
                property var days: ["Pazar","Pazartesi","Salı","Çarşamba","Perşembe","Cuma","Cumartesi"]
                property var mons: ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]
                text: days[d.getDay()] + ",  " + d.getDate() + " " + mons[d.getMonth()] + " " + d.getFullYear()
                font.pixelSize: 10; color: "#7f849c"
            }
        }
    }
}
