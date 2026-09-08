import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: osdWindow

    property var targetItem: null
    property bool connected: false
    property string ssid: ""
    property int signalPct: 0
    property string security: ""
    property bool osdVisible: false

    color: "transparent"
    visible: osdVisible || contentContainer.opacity > 0.001

    anchor {
        item: osdWindow.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
    }

    implicitWidth: 300
    implicitHeight: 120

    Timer {
        id: dismissTimer
        interval: 2200
        repeat: false
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

    // keep in sync with Network.qml pctToBars() and NetworkRow.qml signalBars()
    function litBars(pct) {
        if (pct >= 80) return 4
        if (pct >= 55) return 3
        if (pct >= 30) return 2
        if (pct > 0) return 1
        return 0
    }

    readonly property string titleText: connected
                                        ? ((ssid && ssid.length > 0) ? ssid : "Wi‑Fi")
                                        : "Wi‑Fi Kapalı"

    readonly property string statusText: connected ? "Bağlı" : "Bağlı Değil"

    readonly property string detailText: connected
                                        ? ("Sinyal " + signalPct + "% · " + ((security && security.length > 0) ? security : "Açık"))
                                        : "Aktif ağ yok"

    Rectangle {
        id: contentContainer
        width: 260
        height: tipLayout.implicitHeight + 22
        radius: 14
        color: Qt.rgba(0.06, 0.07, 0.09, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale: osdWindow.osdVisible ? 1.0 : 0.93
        y: osdWindow.osdVisible ? 14 : -40

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: tipLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: osdWindow.titleText
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.45)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: osdWindow.statusText
                    font.pixelSize: 11
                    font.bold: true
                    color: osdWindow.connected ? theme.accentActive : Qt.rgba(1, 1, 1, 0.40)
                }
            }

            Text {
                Layout.fillWidth: true
                text: osdWindow.detailText
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.86)
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: osdWindow.connected

                Item {
                    width: 15
                    height: 13
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: 4

                        Rectangle {
                            property int barH: [4, 6, 9, 13][index]
                            property bool lit: osdWindow.litBars(osdWindow.signalPct) > index

                            width: 2.5
                            height: barH
                            radius: 1.2
                            x: index * 4
                            y: 13 - barH
                            color: lit ? theme.accentActive : Qt.rgba(1, 1, 1, 0.15)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 5
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, osdWindow.signalPct / 100))
                        height: parent.height
                        radius: 3
                        color: "#74c7ec"

                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
