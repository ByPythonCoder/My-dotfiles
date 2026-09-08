import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    Theme { id: theme }

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

    property int playOffsetX: 1
    property int playOffsetY: -1
    property int pauseOffsetX: 0
    property int pauseOffsetY: -1

    property bool scrubbing: false
    property real scrubProgress: 0.0
    property real scrubPosition: 0.0

    readonly property real shownProgress: scrubbing ? scrubProgress : progress

    signal previousRequested()
    signal toggleRequested()
    signal nextRequested()
    signal seekRequested(real seconds)
    signal hoveredChanged(bool hovered)

    onProgressChanged: {
        if (!scrubbing) {
            scrubProgress = Math.max(0, Math.min(1, progress))
            scrubPosition = scrubProgress * duration
        }
    }

    onDurationChanged: {
        if (!scrubbing) {
            scrubProgress = Math.max(0, Math.min(1, progress))
            scrubPosition = scrubProgress * duration
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds))
            return "0:00"

        const total = Math.floor(seconds)
        const mins = Math.floor(total / 60)
        const secs = total % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: 10
            color: theme.bgSurface
            clip: true

            Image {
                anchors.fill: parent
                source: artUrl
                fillMode: Image.PreserveAspectCrop
                visible: artUrl !== ""
                asynchronous: true
                cache: true
            }

            Text {
                anchors.centerIn: parent
                text: "♪"
                color: theme.textDim
                visible: artUrl === ""
                font.pixelSize: 20
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Text {
                text: title || "Oynatılan yok"
                color: theme.textPrimary
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: artist
                color: theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
                visible: artist !== ""
                Layout.fillWidth: true
            }

            Text {
                text: album !== "" ? album + (playerIdentity !== "" ? " • " + playerIdentity : "") : playerIdentity
                color: theme.textDim
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: album !== "" || playerIdentity !== ""
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Item {
                    id: scrubber
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    function clamp01(v) {
                        return Math.max(0, Math.min(1, v))
                    }

                    function ratioFromMouse(mouse) {
                        const p = scrubArea.mapToItem(trackBg, mouse.x, mouse.y)
                        return clamp01(p.x / Math.max(1, trackBg.width))
                    }

                    function setFromMouse(mouse) {
                        const ratio = ratioFromMouse(mouse)
                        root.scrubProgress = ratio
                        root.scrubPosition = ratio * root.duration
                    }

                    Rectangle {
                        id: trackBg
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 8
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    Rectangle {
                        id: trackFill
                        anchors.left: trackBg.left
                        anchors.verticalCenter: trackBg.verticalCenter
                        width: trackBg.width * scrubber.clamp01(root.shownProgress)
                        height: trackBg.height
                        radius: 4
                        visible: width > 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: theme.archBlue }
                            GradientStop { position: 1.0; color: theme.archCyan }
                        }
                    }

                    Rectangle {
                        id: scrubHandle
                        visible: canSeek && root.shownProgress > 0
                        width: 4
                        height: 14
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.9)
                        anchors.verticalCenter: trackBg.verticalCenter
                        x: trackBg.x + trackBg.width * scrubber.clamp01(root.shownProgress) - width / 2
                    }

                    MouseArea {
                        id: scrubArea
                        anchors.fill: parent
                        enabled: canSeek && duration > 0
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onPressed: function(mouse) {
                            root.scrubbing = true
                            scrubber.setFromMouse(mouse)
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed)
                                scrubber.setFromMouse(mouse)
                        }

                        onReleased: function(mouse) {
                            if (!root.scrubbing)
                                return

                            scrubber.setFromMouse(mouse)
                            root.seekRequested(root.scrubPosition)
                            root.scrubbing = false
                        }

                        onCanceled: {
                            root.scrubbing = false
                            root.scrubProgress = Math.max(0, Math.min(1, root.progress))
                            root.scrubPosition = root.scrubProgress * root.duration
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.scrubbing ? root.formatTime(root.scrubPosition) : positionText
                        color: theme.textDim
                        font.pixelSize: 9
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: lengthText
                        color: theme.textDim
                        font.pixelSize: 9
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: canGoPrevious ? theme.bgHover : theme.bgSurface
                    opacity: canGoPrevious ? 1.0 : 0.5

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "⏮"
                        color: theme.textPrimary
                        font.pixelSize: 11
                    }

                    TapHandler {
                        enabled: canGoPrevious
                        onTapped: root.previousRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 19
                    color: canTogglePlaying ? theme.archCyan : theme.bgSurface
                    opacity: canTogglePlaying ? 1.0 : 0.5

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        lineHeight: 1.0
                        text: isPlaying ? "⏸" : "▶"
                        color: canTogglePlaying ? theme.bgSurface : theme.textDim
                        font.pixelSize: 14
                        font.bold: true
                        anchors.horizontalCenterOffset: isPlaying ? pauseOffsetX : playOffsetX
                        anchors.verticalCenterOffset: isPlaying ? pauseOffsetY : playOffsetY
                    }

                    TapHandler {
                        enabled: canTogglePlaying
                        onTapped: root.toggleRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14
                    color: canGoNext ? theme.bgHover : theme.bgSurface
                    opacity: canGoNext ? 1.0 : 0.5

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "⏭"
                        color: theme.textPrimary
                        font.pixelSize: 11
                    }

                    TapHandler {
                        enabled: canGoNext
                        onTapped: root.nextRequested()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
