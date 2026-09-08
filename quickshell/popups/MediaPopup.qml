import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

PopupWindow {
    id: rootPopup

    property var targetItem: null
    property bool visibleState: false

    property string title: ""
    property string artist: ""
    property string album: ""
    property string playerIdentity: ""
    property string artUrl: ""

    property bool isPlaying: false
    property real progress: 0.0
    property string positionText: "0:00"
    property string lengthText: "0:00"

    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property real duration: 0

    property real scrubPosition: 0
    property real scrubProgress: 0
    property bool scrubbing: false

    signal previousRequested()
    signal toggleRequested()
    signal nextRequested()
    signal seekRequested(real seconds)
    signal hoveredChanged(bool hovered)

    color: "transparent"
    implicitWidth: 340
    implicitHeight: 520
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
        width: 300
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: rootPopup.visibleState ? 1.0 : 0.0
        scale: rootPopup.visibleState ? 1.0 : 0.95
        y: rootPopup.visibleState ? 14 : -20

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.02 } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: rootPopup.hoveredChanged(hovered)
        }

        height: Math.min(480, contentCol.implicitHeight + 20)

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Empty state

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: rootPopup.title === "" && rootPopup.artist === ""

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf025"
                        font.pixelSize: 48
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Oynatılan medya yok"
                        font.pixelSize: theme.fontMd
                        color: theme.textMuted
                    }
                }
            }

            // Player identity

            Text {
                Layout.fillWidth: true
                visible: rootPopup.playerIdentity !== "" && rootPopup.title !== ""
                text: rootPopup.playerIdentity
                font.pixelSize: theme.fontSm
                color: theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            // Album art

            Item {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                Layout.alignment: Qt.AlignHCenter
                visible: rootPopup.title !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Image {
                        anchors.fill: parent
                        source: rootPopup.artUrl
                        sourceSize.width: 200
                        sourceSize.height: 200
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: rootPopup.artUrl !== ""

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf025"
                        font.pixelSize: 48
                        color: Qt.rgba(1, 1, 1, 0.12)
                        visible: rootPopup.artUrl === ""
                    }
                }
            }

            // Title and artist

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: rootPopup.title !== ""

                Text {
                    Layout.fillWidth: true
                    text: rootPopup.title
                    font.pixelSize: theme.fontLg
                    font.weight: Font.Bold
                    color: theme.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: rootPopup.artist
                    font.pixelSize: theme.fontMd
                    color: theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // Seek bar

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                visible: rootPopup.title !== ""

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Rectangle {
                            width: parent.width * rootPopup.scrubProgress
                            height: parent.height
                            radius: 3
                            visible: width > 0
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: theme.archBlue }
                                GradientStop { position: 1.0; color: theme.archCyan }
                            }

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPressed: function(mouse) {
                                if (!rootPopup.canSeek) return
                                rootPopup.scrubbing = true
                                var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                rootPopup.scrubPosition = ratio * rootPopup.duration
                                rootPopup.scrubProgress = ratio
                            }
                            onPositionChanged: function(mouse) {
                                if (!rootPopup.scrubbing) return
                                var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                rootPopup.scrubPosition = ratio * rootPopup.duration
                                rootPopup.scrubProgress = ratio
                            }
                            onReleased: function(mouse) {
                                if (!rootPopup.scrubbing) return
                                rootPopup.scrubbing = false
                                rootPopup.seekRequested(rootPopup.scrubPosition)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: rootPopup.positionText
                            font.pixelSize: 10
                            color: theme.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: rootPopup.lengthText
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                    }
                }
            }

            // Transport controls

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                visible: rootPopup.title !== ""

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    Text {
                        text: "\uf04a"
                        font.pixelSize: 22
                        color: rootPopup.canGoPrevious ? theme.textPrimary : Qt.rgba(1, 1, 1, 0.2)
                        opacity: enabled ? 1.0 : 0.4
                        enabled: rootPopup.canGoPrevious

                        TapHandler {
                            onTapped: {
                                if (rootPopup.canGoPrevious)
                                    rootPopup.previousRequested()
                            }
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: rootPopup.isPlaying ? "\uf04c" : "\uf04b"
                            font.pixelSize: 22
                            color: theme.textPrimary

                            TapHandler {
                                onTapped: rootPopup.toggleRequested()
                            }
                        }
                    }

                    Text {
                        text: "\uf04e"
                        font.pixelSize: 22
                        color: rootPopup.canGoNext ? theme.textPrimary : Qt.rgba(1, 1, 1, 0.2)
                        opacity: enabled ? 1.0 : 0.4
                        enabled: rootPopup.canGoNext

                        TapHandler {
                            onTapped: {
                                if (rootPopup.canGoNext)
                                    rootPopup.nextRequested()
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 4
            }
        }
    }
}
