import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "."
import ".."
import "../components"

PopupWindow {
    id: rootPopup

    property var targetItem: null
    property bool visibleState: false

    property var focusedMonitor: Hyprland.focusedMonitor
    property var workspaces: Hyprland.workspaces

    readonly property var wsList: {
        var list = []
        var monName = focusedMonitor ? focusedMonitor.name : ""
        for (var i = 0; i < workspaces.length; i++) {
            var ws = workspaces[i]
            if (ws.monitor && ws.monitor.name === monName)
                list.push(ws)
        }
        list.sort(function(a, b) { return a.id - b.id })
        return list
    }

    property int focusedId: focusedMonitor ? focusedMonitor.activeWorkspace.id : -1

    color: "transparent"
    implicitWidth: 260
    implicitHeight: 400
    visible: visibleState || container.opacity > 0.001
    grabFocus: true

    anchor {
        item: rootPopup.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
        margins.top: 10
    }

    property int _curIndex: 0

    function open() {
        visibleState = true
        _curIndex = 0
        for (var i = 0; i < wsList.length; i++) {
            if (wsList[i].id === focusedId) {
                _curIndex = i
                break
            }
        }
        if (anchor && anchor.updateAnchor)
            anchor.updateAnchor()
    }

    function close() {
        visibleState = false
    }

    function switchTo(index) {
        if (index >= 0 && index < wsList.length) {
            wsList[index].activate()
            close()
        }
    }

    function navigate(dir) {
        var newIdx = _curIndex + dir
        if (newIdx >= 0 && newIdx < wsList.length) {
            _curIndex = newIdx
            listView.positionViewAtIndex(_curIndex, ListView.Contain)
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: rootPopup.visibleState

        Keys.onPressed: function(event) {
            switch (event.key) {
                case Qt.Key_Up:
                case Qt.Key_Left:
                    rootPopup.navigate(-1)
                    break
                case Qt.Key_Down:
                case Qt.Key_Right:
                    rootPopup.navigate(1)
                    break
                case Qt.Key_Return:
                case Qt.Key_Space:
                    rootPopup.switchTo(_curIndex)
                    break
            }
        }

        GlassPanel {
            id: container
            width: 240
            anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.95
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.02 } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        height: Math.min(380, contentCol.implicitHeight + 20)

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Text {
                text: "Çalışma Alanları"
                font.pixelSize: 13
                font.bold: true
                color: Qt.rgba(1, 1, 1, 0.94)
                Layout.bottomMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(count * 52, 320)
                model: rootPopup.wsList
                spacing: 3
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: wsDelegate

                    required property var modelData
                    required property int index

                    property bool isFocused: modelData && modelData.id === rootPopup.focusedId
                    property bool isSelected: index === rootPopup._curIndex
                    property bool hovered: false
                    property bool pressed: false

                    width: parent ? parent.width : 220
                    height: 46
                    scale: pressed ? 0.988 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: wsDelegate.isFocused
                               ? Qt.rgba(0.68, 0.64, 0.86, 0.12)
                               : (wsDelegate.isSelected ? Qt.rgba(1, 1, 1, 0.06)
                                  : (wsDelegate.hovered ? Qt.rgba(1, 1, 1, 0.04)
                                     : "transparent"))
                        border.width: wsDelegate.isFocused ? 1 : (wsDelegate.isSelected ? 1 : 0)
                        border.color: wsDelegate.isFocused
                                      ? Qt.rgba(0.68, 0.64, 0.86, 0.30)
                                      : (wsDelegate.isSelected ? Qt.rgba(1, 1, 1, 0.12)
                                         : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: modelData ? String(modelData.id) : ""
                            font.pixelSize: 13
                            font.weight: wsDelegate.isFocused ? Font.DemiBold : Font.Medium
                            color: wsDelegate.isFocused
                                   ? theme.archCyan
                                   : (wsDelegate.isSelected
                                      ? Qt.rgba(1, 1, 1, 0.85)
                                      : Qt.rgba(1, 1, 1, 0.60))
                            Layout.preferredWidth: 28
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: modelData ? ("Alan " + modelData.id) : ""
                                font.pixelSize: 11
                                font.weight: wsDelegate.isFocused ? Font.DemiBold : Font.Medium
                                color: wsDelegate.isFocused
                                       ? Qt.rgba(1, 1, 1, 0.94)
                                       : Qt.rgba(1, 1, 1, 0.78)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: {
                                    var count = modelData ? modelData.toplevels.values.length : 0
                                    if (count === 0) return "Boş"
                                    if (count === 1) return "1 pencere"
                                    return count + " pencere"
                                }
                                font.pixelSize: 9
                                color: wsDelegate.isFocused
                                       ? Qt.rgba(0.20, 0.78, 0.42, 0.70)
                                       : Qt.rgba(1, 1, 1, 0.30)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            visible: wsDelegate.isFocused
                            radius: 6
                            color: Qt.rgba(0.68, 0.64, 0.86, 0.18)
                            border.width: 0.5
                            border.color: Qt.rgba(0.68, 0.64, 0.86, 0.30)
                            implicitWidth: currentLabel.implicitWidth + 10
                            implicitHeight: 18
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                id: currentLabel
                                anchors.centerIn: parent
                                text: "Aktif"
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: theme.archCyan
    }
}

                    HoverHandler { onHoveredChanged: wsDelegate.hovered = hovered }

                    TapHandler {
                        onPressedChanged: wsDelegate.pressed = pressed
                        onTapped: rootPopup.switchTo(index)
                    }
                }
            }
        }
    }
    }
}
}
