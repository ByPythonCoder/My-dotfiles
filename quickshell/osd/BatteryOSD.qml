import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: osdWindow

    property var targetItem: null
    property string timeStr: ""
    property bool charging: false
    property bool full: false

    color:   "transparent"
    visible: osdVisible || contentContainer.opacity > 0.001

    anchor {
        item:  osdWindow.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
    }

    implicitWidth:  150
    implicitHeight: 100

    property bool osdVisible: false

    function open()  { osdVisible = true }
    function close() { osdVisible = false }

    Rectangle {
        id: contentContainer
        width:  100
        height: 46
        radius: 6
        color:  Qt.rgba(0.06, 0.07, 0.09, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale:   osdWindow.osdVisible ? 1.0 : 0.93
        y:       osdWindow.osdVisible ? 14  : -40

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack  } }
        Behavior on y       { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 8
            spacing: 1

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: osdWindow.full ? "Tam Şarjlı" : (osdWindow.charging ? "Şarj Ediliyor" : "Boşaltılıyor")
                font.pixelSize:  10
                font.weight:     Font.Medium
                color:           Qt.rgba(1, 1, 1, 0.45)
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (osdWindow.full) return "Takılı";
                    if (osdWindow.timeStr === "") return "Hesaplanıyor...";
                    return osdWindow.charging ? osdWindow.timeStr + " dolana" : osdWindow.timeStr + " kaldı";
                }
                font.pixelSize: 11
                font.bold:      true
                color:          "#00b4d8"
            }
        }
    }
}
