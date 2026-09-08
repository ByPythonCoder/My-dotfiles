import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../osd"
import "../popups"
import ".."

Item {
    id: root

    Theme { id: theme }

    property var popupManager: null

    WorkspaceOverview {
        id: wsOverview
        targetItem: container
    }

    property var wsOverview: wsOverview

    property int activeId: Hyprland.focusedMonitor
                           ? Hyprland.focusedMonitor.activeWorkspace.id
                           : 1

    property var occupiedIds: {
        var ids = {}
        var ws = Hyprland.workspaces.values
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].toplevels.values.length > 0) ids[ws[i].id] = true
        }
        return ids
    }

    property var visibleWorkspaceIds: {
        var ids = []
        var ws = Hyprland.workspaces.values
        for (var i = 0; i < ws.length; i++) {
            var id = ws[i].id
            if (ws[i].toplevels.values.length > 0 || id === activeId)
                ids.push(id)
        }
        ids.sort(function(a, b) { return a - b })
        return ids
    }

    implicitWidth:  wsRow.implicitWidth
    implicitHeight: theme.barHeight

    Item {
        id: container
        anchors.verticalCenter: parent.verticalCenter
        width: wsRow.width
        height: theme.wsHeight

        Rectangle {
            id: activeIndicator
            width: theme.wsWidth
            height: theme.wsHeight
            radius: theme.wsRadius
            color: Qt.rgba(0.68, 0.64, 0.86, 0.18)
            border.width: 0.5
            border.color: Qt.rgba(0.68, 0.64, 0.86, 0.55)

            property int activeIndex: root.visibleWorkspaceIds.indexOf(root.activeId)
            x: activeIndex >= 0 ? activeIndex * (theme.wsWidth + theme.gapSm) : 0
            visible: activeIndex >= 0

            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                if (popupManager)
                    popupManager.toggleMajor("workspace")
            }
        }

        Row {
            id: wsRow
            spacing: theme.gapSm

            Repeater {
                model: root.visibleWorkspaceIds

                delegate: Item {
                    id: pill

                    required property var modelData
                    property int  wsId:      modelData
                    property bool isActive:   root.activeId === wsId
                    property bool isOccupied: root.occupiedIds[wsId] === true

                    implicitWidth:  theme.wsWidth
                    implicitHeight: theme.wsHeight

                    Rectangle {
                        id: bg
                        anchors.fill: parent
                        radius: theme.wsRadius
                        color: hov.hovered && !pill.isActive ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        border.width: 0.5
                        border.color: hov.hovered && !pill.isActive ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                        Behavior on color        { ColorAnimation { duration: theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: theme.animFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: pill.wsId
                        font.family:    theme.fontFamily
                        font.pixelSize: theme.fontBase
                        font.weight:    pill.isActive ? theme.weightMed : theme.weightNormal
                        color: pill.isActive   ? theme.archCyan
                             : pill.isOccupied ? theme.textPrimary
                             :                  theme.textMuted
                        Behavior on color { ColorAnimation { duration: theme.animFast } }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        width: 3; height: 3; radius: 1.5
                        color:   pill.isActive ? theme.archCyan : theme.archBlue
                        opacity: pill.isOccupied ? (pill.isActive ? 0.9 : 0.7) : 0
                        Behavior on opacity { NumberAnimation { duration: theme.animMed } }
                        Behavior on color   { ColorAnimation  { duration: theme.animFast } }
                    }

                    transform: Scale {
                        origin.x: pill.implicitWidth  / 2
                        origin.y: pill.implicitHeight / 2
                        xScale: pill.isActive ? 1.08 : (hov.hovered ? 1.03 : 1.0)
                        yScale: xScale
                        Behavior on xScale {
                            NumberAnimation { duration: theme.animMed; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        }
                    }

                    HoverHandler { id: hov }

                    TapHandler   {
                        onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = " + pill.wsId + " })")
                    }
                    WheelHandler {
                        onWheel: (e) => {
                            if (e.angleDelta.y > 0) {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = 'e-1' })")
                            } else {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = 'e+1' })")
                            }
                        }
                    }
                }
            }
        }
    }
}
