import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    signal controlPressed()

    UserConfig {
        id: userConfig
    }

    property bool showCondition: false
    property string currentArtUrl: ""
    property string currentTrack: ""
    property string currentArtist: ""
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"
    property real trackProgress: 0
    property var activePlayer: null
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property real visualizerPhase: 0
    property real transitionProgress: 0

    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property real clampedProgress: Math.max(0, Math.min(1, trackProgress))
    readonly property real revealProgress: showCondition ? 1 : 0

    function visualizerLevel(index) {
        const phase = visualizerPhase + index * 0.8;
        const primary = (Math.sin(phase) + 1) * 0.5;
        const secondary = (Math.sin(phase * 2.1 + index * 0.9) + 1) * 0.5;
        return 0.22 + primary * 0.5 + secondary * 0.16;
    }

    function pausedVisualizerLevel(index) {
        const levels = [0.36, 0.58, 0.86, 0.58, 0.36];
        return levels[index] || 0.45;
    }

    function togglePlayback() {
        if (!activePlayer || !activePlayer.canControl)
            return;

        if (activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying();
            return;
        }

        if (activePlayer.playbackState === MprisPlaybackState.Playing) {
            if (activePlayer.canPause)
                activePlayer.pause();
            return;
        }

        if (activePlayer.canPlay)
            activePlayer.play();
    }

    anchors.fill: parent
    anchors.margins: 12
    opacity: revealProgress
    visible: opacity > 0
    x: -width * transitionProgress

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 280 : 160
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
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

    Column {
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        scale: 0.982 + root.revealProgress * 0.018

        Behavior on scale {
            NumberAnimation {
                duration: root.showCondition ? 280 : 160
                easing.type: Easing.InOutCubic
            }
        }

        Item {
            width: parent.width
            height: 56

            Row {
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    width: 56
                    height: 56
                    radius: 13
                    color: "#1e1f22"
                    border.width: 1
                    border.color: "#2f3136"
                    clip: true

                    Image {
                        id: artImage

                        anchors.fill: parent
                        source: root.currentArtUrl
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(112, 112)
                        visible: source.toString() !== ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: !artImage.visible
                        color: "#292a2e"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            radius: 7
                            color: "#707684"
                        }
                    }
                }

                Column {
                    width: Math.max(120, parent.width - 56 - 10 - 34 - 10)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.currentTrack !== "" ? root.currentTrack : "No media playing"
                        color: "#f5f6f8"
                        font.pixelSize: 14
                        font.family: root.textFontFamily
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.12
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    Text {
                        width: parent.width
                        text: root.currentArtist !== "" ? root.currentArtist : "Unknown artist"
                        color: "#989ca6"
                        font.pixelSize: 11
                        font.family: root.textFontFamily
                        font.weight: Font.Medium
                        font.letterSpacing: -0.08
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                }

                Item {
                    width: 34
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: 5

                            delegate: Rectangle {
                                width: 3
                                height: root.isPlaying
                                    ? 5 + 13 * root.visualizerLevel(index)
                                    : 5 + 13 * root.pausedVisualizerLevel(index)
                                radius: 1.5
                                color: root.isPlaying ? "#ff7f62" : "#6e534b"
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

        Item {
            width: parent.width
            height: 22

            Text {
                id: elapsedText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.timePlayed
                color: "#8f939c"
                font.pixelSize: 10
                font.family: root.textFontFamily
                font.weight: Font.Medium
            }

            Text {
                id: totalText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeTotal
                color: "#8f939c"
                font.pixelSize: 10
                font.family: root.textFontFamily
                font.weight: Font.Medium
            }

            Rectangle {
                anchors.left: elapsedText.right
                anchors.right: totalText.left
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 7
                radius: 3.5
                color: "#2b2d33"

                Rectangle {
                    height: parent.height
                    width: parent.width * root.clampedProgress
                    radius: parent.radius
                    color: "#f5f6f8"

                    Behavior on width {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 30

            Row {
                anchors.centerIn: parent
                spacing: 44

                Item {
                    width: 28
                    height: 28
                    scale: prevArea.pressed ? 0.88 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 90 }
                    }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        iconName: "skip-back"
                        opacity: prevArea.pressed ? 0.74 : 1
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true

                        onPressed: (mouse) => {
                            root.controlPressed();
                            mouse.accepted = true;
                        }

                        onClicked: {
                            if (root.activePlayer && root.activePlayer.canGoPrevious)
                                root.activePlayer.previous();
                        }
                    }
                }

                Item {
                    width: 30
                    height: 30
                    scale: playArea.pressed ? 0.88 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 90 }
                    }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        iconName: root.isPlaying ? "pause" : "play"
                        opacity: playArea.pressed ? 0.74 : 1
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true

                        onPressed: (mouse) => {
                            root.controlPressed();
                            mouse.accepted = true;
                        }

                        onClicked: root.togglePlayback()
                    }
                }

                Item {
                    width: 28
                    height: 28
                    scale: nextArea.pressed ? 0.88 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 90 }
                    }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        iconName: "skip-forward"
                        opacity: nextArea.pressed ? 0.74 : 1
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true

                        onPressed: (mouse) => {
                            root.controlPressed();
                            mouse.accepted = true;
                        }

                        onClicked: {
                            if (root.activePlayer && root.activePlayer.canGoNext)
                                root.activePlayer.next();
                        }
                    }
                }

            }
        }
    }
}
