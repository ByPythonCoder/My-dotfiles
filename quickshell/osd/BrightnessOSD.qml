import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: osdWindow

    property var targetItem: null
    property int brightness: 0

    color:   "transparent"
    visible: osdVisible || contentContainer.opacity > 0.001

    anchor {
        item:  osdWindow.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
    }

    implicitWidth:  320
    implicitHeight: 140

    property bool osdVisible: false

    Timer {
        id: dismissTimer
        interval: 1400
        repeat:   false
        onTriggered: osdWindow.close()
    }

    function open() {
        osdWindow.osdVisible = true
        dismissTimer.restart()
    }

    function close() {
        osdWindow.osdVisible = false
        dismissTimer.stop()
    }

    function trigger() {
        open()
    }

    Rectangle {
        id: contentContainer
        width:  280
        height: 64
        radius: 14
        color:  Qt.rgba(0.06, 0.07, 0.09, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale:   osdWindow.osdVisible ? 1.0 : 0.93
        y:       osdWindow.osdVisible ? 14   : -40

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack  } }
        Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text:            "Parlaklık"
                    font.pixelSize:  11
                    font.weight:     Font.Medium
                    color:           Qt.rgba(1, 1, 1, 0.45)
                    Layout.fillWidth: true
                }

                Text {
                    text:           osdWindow.brightness + "%"
                    font.pixelSize: 11
                    font.bold:      true
                    color:          "#74c7ec"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    width: 16; height: 16

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6; height: 6; radius: 3
                        color: "#74c7ec"
                        opacity: 0.5 + (osdWindow.brightness / 100) * 0.5
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Repeater {
                        model: 8
                        Rectangle {
                            property real len: (2 + (osdWindow.brightness / 100) * 2)
                            anchors.centerIn: parent
                            width: 1; height: len; radius: 0.5
                            color: "#74c7ec"
                            opacity: 0.4 + (osdWindow.brightness / 100) * 0.6
                            transform: [
                                Translate { y: -5 },
                                Rotation { origin.x: 0.5; origin.y: len / 2; angle: (index / 8) * 360 }
                            ]
                            Behavior on height  { NumberAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 5
                    radius: 3
                    color:  Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        width:  parent.width * (osdWindow.brightness / 100)
                        height: parent.height
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#89b4fa" }
                            GradientStop { position: 1.0; color: "#74c7ec" }
                        }
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
