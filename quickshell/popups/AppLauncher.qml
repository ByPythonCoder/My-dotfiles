import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Scope {
    id: root

    Theme { id: theme }

    property string font: "JetBrainsMono Nerd Font"
    property var targetItem: null
    property int selectedIndex: 0
    property real boxX: 0
    property real boxY: 0

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcherPanel.visible = !launcherPanel.visible
            if (launcherPanel.visible) {
                updatePosition()
                searchInput.text = ""
                selectedIndex = -1
                searchInput.forceActiveFocus()
            }
        }
    }

    function updatePosition() {
        if (targetItem) {
            var pos = targetItem.mapToItem(null, 0, targetItem.height + 8)
            boxX = pos.x
            boxY = pos.y
        } else {
            boxX = (launcherPanel.width - 560) / 2
            boxY = (launcherPanel.height - 480) / 2
        }
    }

    function open() {
        updatePosition()
        launcherPanel.visible = true
        searchInput.text = ""
        selectedIndex = 0
        searchInput.forceActiveFocus()
    }

    function close() {
        launcherPanel.visible = false
    }

    function toggleLauncher() {
        if (launcherPanel.visible) close()
        else open()
    }

    ScriptModel {
        id: filteredApps
        objectProp: "id"
        values: {
            var all = [...DesktopEntries.applications.values]
            var q = searchInput.text.trim().toLowerCase()
            if (q === "") return all.sort(function(a, b) { return a.name.localeCompare(b.name) })
            return all.filter(function(d) {
                return (d.name && d.name.toLowerCase().indexOf(q) >= 0) ||
                       (d.genericName && d.genericName.toLowerCase().indexOf(q) >= 0) ||
                       (d.keywords && d.keywords.some(function(k) { return k.toLowerCase().indexOf(q) >= 0 })) ||
                       (d.categories && d.categories.some(function(c) { return c.toLowerCase().indexOf(q) >= 0 }))
            }).sort(function(a, b) {
                var an = a.name.toLowerCase()
                var bn = b.name.toLowerCase()
                var aStarts = an.indexOf(q) === 0
                var bStarts = bn.indexOf(q) === 0
                if (aStarts && !bStarts) return -1
                if (!aStarts && bStarts) return 1
                return an.localeCompare(bn)
            })
        }
    }

    function launchApp(entry) {
        entry.execute()
        launcherPanel.visible = false
    }

    PanelWindow {
        id: launcherPanel
        visible: false
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: launcherPanel.visible = false

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)
            }
        }

        Rectangle {
            id: launcherBox
            x: root.boxX
            y: root.boxY
            width: 560
            height: 480
            radius: 16
            color: theme.panelBg
            border.color: theme.panelBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "  Uygulamalar"
                    color: theme.archCyan
                    font.pixelSize: 14
                    font.family: root.font
                    font.bold: true
                }

                GridView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: filteredApps
                    clip: true
                    cellWidth: (resultsList.width - 8) / 3
                    cellHeight: 90
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 150

                    highlight: Rectangle {
                        radius: 12
                        color: Qt.rgba(0.68, 0.64, 0.86, 0.12)
                        visible: root.selectedIndex >= 0
                    }

                    delegate: Item {
                        id: gridDelegate
                        required property var modelData
                        required property int index
                        width: resultsList.cellWidth
                        height: resultsList.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 12
                            color: gridDelegate.index === root.selectedIndex
                                   ? Qt.rgba(0.68, 0.64, 0.86, 0.12)
                                   : (gridMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                Item {
                                    width: 48
                                    height: 48
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    IconImage {
                                        anchors.fill: parent
                                        source: Quickshell.iconPath(gridDelegate.modelData.icon ?? "", true)
                                        visible: (gridDelegate.modelData.icon ?? "") !== ""
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: Qt.rgba(0.68, 0.64, 0.86, 0.12)
                                        visible: (gridDelegate.modelData.icon ?? "") === ""

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uF115"
                                            color: theme.archCyan
                                            font.pixelSize: 22
                                            font.family: root.font
                                        }
                                    }
                                }

                                Text {
                                    text: gridDelegate.modelData.name ?? ""
                                    color: gridDelegate.index === root.selectedIndex ? theme.textPrimary : theme.text
                                    font.pixelSize: 11
                                    font.family: theme.fontFamily
                                    font.bold: gridDelegate.index === root.selectedIndex
                                    elide: Text.ElideRight
                                    width: 72
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        MouseArea {
                            id: gridMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchApp(gridDelegate.modelData)
                            onPositionChanged: root.selectedIndex = gridDelegate.index
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "  Uygulama bulunamadı"
                        color: theme.textDim
                        font.pixelSize: 14
                        font.family: root.font
                        visible: resultsList.count === 0 && searchInput.text !== ""
                    }
                }

                Text {
                    text: resultsList.count + " uygulama"
                    color: theme.textDim
                    font.pixelSize: 11
                    font.family: root.font
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 10
                    color: theme.bgHover
                    border.color: searchInput.activeFocus ? theme.archCyan : theme.border
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "\uF002"
                            color: theme.archCyan
                            font.pixelSize: 14
                            font.family: root.font
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: theme.textPrimary
                            font.pixelSize: 15
                            font.family: root.font
                            clip: true
                            focus: true

                            Text {
                                anchors.fill: parent
                                text: "Aramak için yazın..."
                                color: theme.textDim
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: root.selectedIndex = text === "" ? -1 : 0

                            Keys.onEscapePressed: launcherPanel.visible = false

                            Keys.onPressed: function(event) {
                                var cols = 3
                                var total = filteredApps.values.length
                                if (event.key === Qt.Key_Down) {
                                    event.accepted = true
                                    root.selectedIndex = Math.min(root.selectedIndex + cols, total - 1)
                                    resultsList.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true
                                    root.selectedIndex = Math.max(root.selectedIndex - cols, 0)
                                    resultsList.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                } else if (event.key === Qt.Key_Right) {
                                    event.accepted = true
                                    root.selectedIndex = Math.min(root.selectedIndex + 1, total - 1)
                                    resultsList.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                } else if (event.key === Qt.Key_Left) {
                                    event.accepted = true
                                    root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                                    resultsList.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true
                                    if (root.selectedIndex >= 0) {
                                        var entry = filteredApps.values[root.selectedIndex]
                                        if (entry) root.launchApp(entry)
                                    }
                                } else if (event.key === Qt.Key_Tab) {
                                    event.accepted = true
                                    root.selectedIndex = Math.min(root.selectedIndex + 1, total - 1)
                                    resultsList.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintUp.width + 8; height: 18; radius: 4; color: theme.bgHover
                            Text { id: hintUp; anchors.centerIn: parent; text: "↑↓"; color: theme.textDim; font.pixelSize: 10; font.family: root.font }
                        }
                        Text { text: "gezin"; color: theme.textDim; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEnter.width + 8; height: 18; radius: 4; color: theme.bgHover
                            Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: theme.textDim; font.pixelSize: 10; font.family: root.font }
                        }
                        Text { text: "başlat"; color: theme.textDim; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEsc.width + 8; height: 18; radius: 4; color: theme.bgHover
                            Text { id: hintEsc; anchors.centerIn: parent; text: "esc"; color: theme.textDim; font.pixelSize: 10; font.family: root.font }
                        }
                        Text { text: "kapat"; color: theme.textDim; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
