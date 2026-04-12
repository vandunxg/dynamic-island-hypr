import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    required property QtObject adapter
    required property QtObject controller

    readonly property bool transientMode: controller.stateName === "transient_event"
    readonly property bool mediaMode: !transientMode && adapter.mediaAvailable
    readonly property bool notificationMode: !transientMode && !mediaMode && adapter.hasUnreadNotification
    readonly property bool clockMode: !transientMode && !mediaMode && !notificationMode

    readonly property string compactLabel: {
        if (transientMode)
            return `${controller.transientKind === "brightness" ? adapter.brightnessPercent : adapter.volumePercent}%`;
        if (mediaMode)
            return adapter.mediaTitle;
        if (notificationMode)
            return Translation.tr("%1 new").arg(Notifications.unread);
        return DateTime.time;
    }

    readonly property string compactIcon: {
        if (transientMode)
            return controller.transientKind === "brightness" ? "light_mode" : (adapter.volumeMuted ? "volume_off" : "volume_up");
        if (notificationMode)
            return "notifications_active";
        if (clockMode)
            return "history";
        return "music_note";
    }

    readonly property color accentColor: {
        if (clockMode)
            return Qt.rgba(1, 0.67, 0.14, 0.98);
        if (notificationMode)
            return Qt.rgba(1, 0.36, 0.36, 0.98);
        if (transientMode)
            return Qt.rgba(0.58, 0.83, 1, 0.98);
        return Qt.rgba(1, 1, 1, 0.95);
    }

    readonly property bool showArtwork: mediaMode && adapter.mediaArtworkUrl !== ""

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        spacing: 8

        Rectangle {
            id: leadingChip
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 22
            implicitHeight: 22
            radius: Appearance.rounding.full
            color: showArtwork ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)

            Image {
                anchors.fill: parent
                source: adapter.mediaArtworkUrl
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: root.showArtwork

                layer.enabled: true
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: leadingChip.width
                        height: leadingChip.height
                        radius: leadingChip.radius
                    }
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.showArtwork
                text: root.compactIcon
                iconSize: Appearance.font.pixelSize.normal
                color: root.accentColor
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: root.mediaMode ? Text.AlignLeft : Text.AlignHCenter
            elide: Text.ElideRight
            text: root.compactLabel
            color: root.accentColor
            font.pixelSize: root.clockMode ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.small
            font.family: root.clockMode ? Appearance.font.family.numbers : Appearance.font.family.main
            font.variableAxes: root.clockMode ? Appearance.font.variableAxes.numbers : Appearance.font.variableAxes.main
            font.bold: root.clockMode
        }

        Item {
            id: indicatorHost
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 24
            implicitHeight: 12

            property real phase: 0

            FrameAnimation {
                running: adapter.mediaPlaying
                onTriggered: indicatorHost.phase = (indicatorHost.phase + 0.45) % 22
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        implicitWidth: 3
                        implicitHeight: adapter.mediaPlaying ? (3 + Math.abs(Math.sin(indicatorHost.phase + index * 0.7)) * 5) : 3
                        radius: Appearance.rounding.full
                        color: root.clockMode ? Qt.rgba(1, 0.67, 0.14, 0.85) : Qt.rgba(0.49, 0.82, 1, adapter.mediaPlaying ? 0.96 : 0.72)

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 90
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.notificationMode
                anchors.right: parent.right
                anchors.top: parent.top
                implicitWidth: 7
                implicitHeight: 7
                radius: Appearance.rounding.full
                color: Qt.rgba(1, 0.36, 0.36, 1)
            }
        }
    }
}
