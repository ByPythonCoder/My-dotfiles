import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "."
import ".."
import "../components"

PopupWindow {
    id: rootPopup

    property var targetItem: null
    property bool visibleState: false

    readonly property var nodes: Pipewire.nodes.values

    readonly property var sinks: {
        var list = []
        for (var i = 0; i < nodes.length; i++) {
            if (!nodes[i].isStream && nodes[i].isSink)
                list.push(nodes[i])
        }
        list.sort(function(a, b) { return (a.description || "").localeCompare(b.description || "") })
        return list
    }

    readonly property var sources: {
        var list = []
        for (var i = 0; i < nodes.length; i++) {
            if (!nodes[i].isStream && !nodes[i].isSink && nodes[i].audio)
                list.push(nodes[i])
        }
        list.sort(function(a, b) { return (a.description || "").localeCompare(b.description || "") })
        return list
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    color: "transparent"
    implicitWidth: 300
    implicitHeight: 440
    visible: visibleState || container.opacity > 0.001

    anchor {
        item: rootPopup.targetItem
        edges: Edges.Bottom | Edges.HorizontalCenter
        gravity: Edges.Bottom | Edges.HorizontalCenter
        margins.top: 10
    }

    function open() {
        visibleState = true
        if (anchor && anchor.updateAnchor)
            anchor.updateAnchor()
    }

    function close() {
        visibleState = false
    }

    function switchSink(device) {
        if (device && device !== defaultSink)
            Pipewire.preferredDefaultAudioSink = device
    }

    function switchSource(device) {
        if (device && device !== defaultSource)
            Pipewire.preferredDefaultAudioSource = device
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => {
            var cp = mapToItem(container, mouse.x, mouse.y)
            if (!container.contains(cp))
                rootPopup.close()
            else
                mouse.accepted = false
        }
    }

    GlassPanel {
        id: container
        width: 280
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.97
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        height: Math.min(410, contentCol.implicitHeight + 20)

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text {
                text: "Çıkış"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Qt.rgba(1, 1, 1, 0.42)
                visible: rootPopup.sinks.length > 0
            }

            Column {
                Layout.fillWidth: true
                spacing: 3
                visible: rootPopup.sinks.length > 0

                Repeater {
                    model: rootPopup.sinks

                    delegate: AudioDeviceRow {
                        required property var modelData
                        width: parent.width
                        device: modelData
                        active: modelData === rootPopup.defaultSink
                        accentColor: theme.archCyan
                        onActivated: rootPopup.switchSink(modelData)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                Layout.topMargin: 4
                visible: rootPopup.sinks.length > 0 && rootPopup.sources.length > 0
            }

            Text {
                text: "Giriş"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Qt.rgba(1, 1, 1, 0.42)
                visible: rootPopup.sources.length > 0
                Layout.topMargin: visible ? 4 : 0
            }

            Column {
                Layout.fillWidth: true
                spacing: 3
                visible: rootPopup.sources.length > 0

                Repeater {
                    model: rootPopup.sources

                    delegate: AudioDeviceRow {
                        required property var modelData
                        width: parent.width
                        device: modelData
                        active: modelData === rootPopup.defaultSource
                        accentColor: theme.accentActive
                        onActivated: rootPopup.switchSource(modelData)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 12
                visible: rootPopup.sinks.length === 0 && rootPopup.sources.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "Ses cihazı bulunamadı"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.38)
                }
            }
        }
    }
}
