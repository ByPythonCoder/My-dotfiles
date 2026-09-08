import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import ".."
import "../popups"

Item {
    id: root
    Theme { id: theme }

    property var popupManager: null

    implicitHeight: theme.barHeight
    implicitWidth: shouldShow ? pillBg.width : 0

    property bool hovered: false
    property bool popupHovered: false
    property bool pausedHold: false

    readonly property var playerList: Mpris.players.values

    readonly property MprisPlayer activePlayer: {
        if (!playerList || playerList.length === 0)
            return null

        for (let i = 0; i < playerList.length; ++i) {
            const p = playerList[i]
            if (p && p.isPlaying)
                return p
        }

        return playerList[0]
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property bool shouldShow: hasPlayer && (isPlaying || pausedHold || mediaPopup.visibleState)

    readonly property string trackTitle:
        activePlayer ? (activePlayer.trackTitle || "Bilinmeyen Şarkı") : ""

    readonly property string trackArtist:
        activePlayer ? (activePlayer.trackArtist || "Bilinmeyen Sanatçı") : ""

    readonly property string trackAlbum:
        activePlayer ? (activePlayer.trackAlbum || "") : ""

    readonly property string playerIdentity:
        activePlayer ? (activePlayer.identity || "") : ""

    readonly property string artUrl:
        activePlayer ? (activePlayer.trackArtUrl || "") : ""

    readonly property real trackPosition:
        activePlayer ? activePlayer.position : 0

    readonly property real trackLength:
        activePlayer ? activePlayer.length : 0

    readonly property real progress:
        (trackLength > 0) ? Math.max(0, Math.min(1, trackPosition / trackLength)) : 0

    readonly property bool canSeek:
        activePlayer ? (activePlayer.canSeek && activePlayer.positionSupported) : false

    readonly property string displayText: {
        if (!activePlayer)
            return ""

        if (trackArtist.length > 0)
            return trackArtist + " — " + trackTitle

        return trackTitle
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds))
            return "0:00"

        const total = Math.floor(seconds)
        const mins = Math.floor(total / 60)
        const secs = total % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    Timer {
        id: pauseHideTimer
        interval: 60000
        repeat: false
        onTriggered: {
            root.pausedHold = false
            if (!root.hovered && !root.popupHovered)
                root.mediaPopup.close()
        }
    }

    Timer {
        id: progressTimer
        interval: 250
        repeat: true
        running: root.activePlayer && root.activePlayer.isPlaying && !mediaPopup.scrubbing
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged()
        }
    }

    onActivePlayerChanged: {
        pausedHold = false
        pauseHideTimer.stop()
    }

    onIsPlayingChanged: {
        if (isPlaying) {
            pausedHold = false
            pauseHideTimer.stop()
        } else if (hasPlayer) {
            pausedHold = true
            pauseHideTimer.restart()
        } else {
            pausedHold = false
            pauseHideTimer.stop()
        }
    }

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: pillBg

        anchors.verticalCenter: parent.verticalCenter
        width: root.hovered ? mediaIcon.width + 6 + 220 + theme.pillPaddingH * 2 : mediaIcon.width + theme.pillPaddingH * 2
        height: 26
        radius: theme.pillRadius
        clip: true

        color: root.hovered ? theme.bgHover : theme.bgSurface

        border.width: 0.5
        border.color: root.hovered ? theme.borderHover : theme.border

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: theme.pillPaddingH
            spacing: 6

            Text {
                id: mediaIcon
                text: isPlaying ? "\uF001" : "\uF04C"
                font.family: "JetBrainsMono Nerd Font"
                color: isPlaying ? theme.archCyan : theme.textMuted
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: mediaText
                text: displayText
                font.family: theme.fontFamily
                font.pixelSize: theme.fontBase
                color: theme.textPrimary
                elide: Text.ElideRight
                width: root.hovered ? 220 : 0
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.hovered ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        HoverHandler {
            onHoveredChanged: root.hovered = hovered
        }

        TapHandler {
            onTapped: {
                if (!root.shouldShow)
                    return
                if (popupManager)
                    popupManager.toggleMajor("media")
            }
        }
    }

    MediaPopup {
        id: mediaPopup
        targetItem: pillBg

        title: trackTitle
        artist: trackArtist
        album: trackAlbum
        playerIdentity: playerIdentity
        artUrl: artUrl

        isPlaying: root.isPlaying
        progress: root.progress
        positionText: root.formatTime(scrubbing ? scrubPosition : root.trackPosition)
        lengthText: root.formatTime(root.trackLength)

        canGoPrevious: root.activePlayer ? root.activePlayer.canGoPrevious : false
        canTogglePlaying: root.activePlayer ? root.activePlayer.canTogglePlaying : false
        canGoNext: root.activePlayer ? root.activePlayer.canGoNext : false
        canSeek: root.canSeek
        duration: root.trackLength

        onHoveredChanged: function(hovered) {
            root.popupHovered = hovered
        }

        onPreviousRequested: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
        onToggleRequested: if (root.activePlayer && root.activePlayer.canTogglePlaying) root.activePlayer.togglePlaying()
        onNextRequested: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()

        onSeekRequested: function(seconds) {
            if (!root.activePlayer || !root.canSeek)
                return

            const clamped = Math.max(0, Math.min(root.trackLength, seconds))

            root.activePlayer.position = clamped
            root.activePlayer.positionChanged()
        }
    }

    property var mediaPopupAlias: mediaPopup
}
