import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

PopupWindow {
    id: osdWindow

    property var targetItem: null

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

    property bool osdVisible: false

    readonly property alias scrubbing: contentItem.scrubbing
    readonly property alias scrubPosition: contentItem.scrubPosition
    readonly property alias scrubProgress: contentItem.scrubProgress

    signal previousRequested()
    signal toggleRequested()
    signal nextRequested()
    signal seekRequested(real seconds)
    signal hoveredChanged(bool hovered)

    readonly property bool osdVisibleEffective: osdVisible || contentContainer.opacity > 0.001

    color: "transparent"
    implicitWidth: 332
    implicitHeight: 200
    visible: osdVisibleEffective

    anchor {
        item: osdWindow.targetItem
        edges: (Edges.Bottom | Edges.HorizontalCenter)
        gravity: (Edges.Bottom | Edges.HorizontalCenter)
    }

    function open() {
        osdVisible = true
    }

    function close() {
        osdVisible = false
    }

    Rectangle {
        id: contentContainer
        width: 300
        height: 150
        radius: 14
        color: Qt.rgba(0.12, 0.12, 0.18, 0.88)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        anchors.horizontalCenter: parent.horizontalCenter

        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale: osdWindow.osdVisible ? 1.0 : 0.94
        y: osdWindow.osdVisible ? 14 : -40

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            onHoveredChanged: osdWindow.hoveredChanged(hovered)
        }

        MediaPlayerContent {
            id: contentItem
            anchors.fill: parent
            anchors.margins: 10

            title: osdWindow.title
            artist: osdWindow.artist
            album: osdWindow.album
            playerIdentity: osdWindow.playerIdentity
            artUrl: osdWindow.artUrl

            isPlaying: osdWindow.isPlaying
            progress: osdWindow.progress
            positionText: osdWindow.positionText
            lengthText: osdWindow.lengthText

            canGoPrevious: osdWindow.canGoPrevious
            canTogglePlaying: osdWindow.canTogglePlaying
            canGoNext: osdWindow.canGoNext
            canSeek: osdWindow.canSeek
            duration: osdWindow.duration

            onPreviousRequested: osdWindow.previousRequested()
            onToggleRequested: osdWindow.toggleRequested()
            onNextRequested: osdWindow.nextRequested()
            onSeekRequested: function(seconds) { osdWindow.seekRequested(seconds) }
            onHoveredChanged: function(h) { osdWindow.hoveredChanged(h) }
        }
    }
}
