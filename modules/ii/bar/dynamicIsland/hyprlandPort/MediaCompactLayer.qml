import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    property bool showCondition: false
    property string currentArtUrl: ""
    property var activePlayer: null
    property real visualizerPhase: 0
    readonly property real revealProgress: showCondition ? 1 : 0

    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

    function visualizerLevel(index) {
        const phase = visualizerPhase + index * 0.75;
        const primary = (Math.sin(phase) + 1) * 0.5;
        const secondary = (Math.sin(phase * 2.2 + index * 1.1) + 1) * 0.5;
        return 0.18 + primary * 0.46 + secondary * 0.20;
    }

    function pausedLevel(index) {
        const levels = [0.30, 0.55, 0.82, 0.55, 0.30, 0.46];
        return levels[index] || 0.4;
    }

    anchors.fill: parent
    anchors.margins: 5
    opacity: revealProgress

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 150
            easing.type: Easing.InOutQuad
        }
    }

    Timer {
        interval: 34
        repeat: true
        running: root.showCondition && root.isPlaying

        onTriggered: {
            root.visualizerPhase += 0.2;
            if (root.visualizerPhase > Math.PI * 2)
                root.visualizerPhase -= Math.PI * 2;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 13
        anchors.rightMargin: 13
        y: (1 - root.revealProgress) * -2

        Behavior on y {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            width: 26
            height: 26
            radius: 7
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: "#1d1d1f"
            border.width: 1
            border.color: "#2b2b2f"
            clip: true

            Image {
                id: artImage

                anchors.fill: parent
                source: root.currentArtUrl
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(52, 52)
                visible: source.toString() !== ""
            }

            Rectangle {
                anchors.fill: parent
                visible: !artImage.visible
                color: "#252527"

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: "#686b70"
                }
            }
        }

        Item {
            width: 40
            height: 16
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 6

                    delegate: Rectangle {
                        width: 3
                        height: root.isPlaying
                            ? 3 + 12 * root.visualizerLevel(index)
                            : 3 + 12 * root.pausedLevel(index)
                        radius: 1.5
                        color: root.isPlaying ? "#78d8ff" : "#4b6478"
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on height {
                            NumberAnimation {
                                duration: root.isPlaying ? 120 : 220
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: root.isPlaying ? 120 : 220
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}
