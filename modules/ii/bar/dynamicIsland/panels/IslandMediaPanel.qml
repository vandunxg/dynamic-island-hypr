import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    required property QtObject adapter

    property bool liked: false

    component MediaControlButton: RippleButton {
        required property string iconName
        required property var triggerAction
        property bool featured: false
        property bool accented: false
        property bool transparentIdle: false
        implicitWidth: featured ? 46 : 38
        implicitHeight: featured ? 46 : 38
        buttonRadius: implicitHeight / 2
        colBackground: {
            if (featured)
                return Qt.rgba(1, 1, 1, 0.94);
            if (accented)
                return Qt.rgba(1, 0.2, 0.2, 0.22);
            if (transparentIdle)
                return Qt.rgba(1, 1, 1, 0);
            return Qt.rgba(1, 1, 1, 0.12);
        }
        colBackgroundHover: {
            if (featured)
                return Qt.rgba(1, 1, 1, 1);
            if (accented)
                return Qt.rgba(1, 0.24, 0.24, 0.3);
            return Qt.rgba(1, 1, 1, transparentIdle ? 0.13 : 0.18);
        }
        colRipple: featured ? Qt.rgba(0.11, 0.11, 0.11, 0.22) : Qt.rgba(1, 1, 1, 0.27)
        downAction: () => {
            if (triggerAction)
                triggerAction();
        }

        contentItem: MaterialSymbol {
            text: iconName
            iconSize: featured ? Appearance.font.pixelSize.hugeass : Appearance.font.pixelSize.huge
            color: {
                if (featured)
                    return Qt.rgba(0.06, 0.06, 0.06, 1);
                if (accented)
                    return Qt.rgba(1, 0.39, 0.39, 0.98);
                return Qt.rgba(1, 1, 1, 0.95);
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fill: 1
        }

        Rectangle {
            visible: accented
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: -1
            implicitWidth: 4
            implicitHeight: 4
            radius: Appearance.rounding.full
            color: Qt.rgba(1, 0.31, 0.31, 1)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                id: artworkFrame
                implicitWidth: 68
                implicitHeight: 68
                radius: 18
                color: Qt.rgba(1, 1, 1, 0.1)

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: adapter.mediaArtworkUrl
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: source !== ""

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artworkFrame.width
                            height: artworkFrame.height
                            radius: artworkFrame.radius
                        }
                    }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: adapter.mediaArtworkUrl === ""
                    text: "music_note"
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Qt.rgba(1, 1, 1, 0.75)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: adapter.mediaTitle
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: Qt.rgba(1, 1, 1, 0.97)
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: adapter.mediaArtist
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Qt.rgba(1, 1, 1, 0.62)
                    elide: Text.ElideRight
                }
            }

            Item {
                implicitWidth: visualizerRow.implicitWidth
                implicitHeight: visualizerRow.implicitHeight

                RowLayout {
                    id: visualizerRow
                    anchors.centerIn: parent
                    spacing: 5

                    Repeater {
                        model: 5
                        Rectangle {
                            required property int index
                            implicitWidth: 4
                            implicitHeight: adapter.mediaPlaying ? (4 + Math.abs(Math.sin(animationBridge.phase + index * 0.75)) * 10) : 4
                            radius: 2
                            color: Qt.rgba(0.48, 0.81, 1, adapter.mediaPlaying ? 0.95 : 0.45)

                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: 110
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }

                Item {
                    id: animationBridge
                    property real phase: 0

                    FrameAnimation {
                        running: adapter.mediaPlaying
                        onTriggered: animationBridge.phase = (animationBridge.phase + 0.4) % 32
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledText {
                text: StringUtils.friendlyTimeForSeconds(adapter.mediaPosition)
                color: Qt.rgba(1, 1, 1, 0.62)
                font.pixelSize: Appearance.font.pixelSize.small
            }

            Loader {
                Layout.fillWidth: true
                active: adapter.mediaCanSeek
                sourceComponent: StyledSlider {
                    configuration: StyledSlider.Configuration.Wavy
                    value: adapter.mediaProgress
                    highlightColor: Qt.rgba(0.95, 0.95, 0.95, 1)
                    trackColor: Qt.rgba(1, 1, 1, 0.2)
                    handleColor: Qt.rgba(0.95, 0.95, 0.95, 0.02)
                    trackWidth: 10
                    animateWave: adapter.mediaPlaying
                    tooltipContent: StringUtils.friendlyTimeForSeconds(value * adapter.mediaLength)
                    onMoved: {
                        adapter.seekTo(value * adapter.mediaLength);
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                active: !adapter.mediaCanSeek
                sourceComponent: StyledProgressBar {
                    value: adapter.mediaProgress
                    valueBarHeight: 10
                    highlightColor: Qt.rgba(0.95, 0.95, 0.95, 1)
                    trackColor: Qt.rgba(1, 1, 1, 0.2)
                    wavy: adapter.mediaPlaying
                    animateWave: adapter.mediaPlaying
                }
            }

            StyledText {
                text: adapter.mediaLength > 0 ? StringUtils.friendlyTimeForSeconds(adapter.mediaLength) : "--:--"
                color: Qt.rgba(1, 1, 1, 0.62)
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            MediaControlButton {
                iconName: adapter.mediaShuffle ? "shuffle_on" : "shuffle"
                triggerAction: () => adapter.toggleShuffle()
                visible: adapter.mediaShuffleSupported
                accented: adapter.mediaShuffle
            }

            MediaControlButton {
                iconName: "skip_previous"
                triggerAction: () => adapter.previousTrack()
                transparentIdle: true
            }

            MediaControlButton {
                iconName: adapter.mediaPlaying ? "pause" : "play_arrow"
                triggerAction: () => adapter.togglePlaying()
                featured: true
            }

            MediaControlButton {
                iconName: "skip_next"
                triggerAction: () => adapter.nextTrack()
                transparentIdle: true
            }

            MediaControlButton {
                iconName: root.liked ? "star" : "star_outline"
                triggerAction: () => root.liked = !root.liked
                transparentIdle: true
            }
        }
    }
}
