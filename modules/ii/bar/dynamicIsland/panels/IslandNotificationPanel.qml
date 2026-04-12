import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property QtObject adapter

    readonly property string mergedText: `${adapter.latestNotificationTitle} ${adapter.latestNotificationBody}`
    readonly property int parsedPercent: {
        const match = mergedText.match(/(\d{1,3})\s?%/);
        if (!match)
            return 95;
        const value = Number.parseInt(match[1]);
        if (isNaN(value))
            return 95;
        return Math.max(0, Math.min(100, value));
    }
    readonly property real progressValue: parsedPercent / 100

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            id: previewCard
            implicitWidth: 110
            implicitHeight: 62
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)

            Image {
                anchors.fill: parent
                source: adapter.latestNotificationImage
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: source !== ""

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: previewCard.width
                        height: previewCard.height
                        radius: previewCard.radius
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: adapter.latestNotificationImage === ""
                text: adapter.latestNotificationAppName.slice(0, 1).toUpperCase()
                color: Qt.rgba(1, 1, 1, 0.8)
                font.pixelSize: Appearance.font.pixelSize.huge
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    text: adapter.latestNotificationTitle
                    color: Qt.rgba(1, 1, 1, 0.96)
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.bold: true
                    elide: Text.ElideRight
                }

                StyledText {
                    text: `${root.parsedPercent}%`
                    color: Qt.rgba(1, 1, 1, 0.92)
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.family: Appearance.font.family.numbers
                    font.variableAxes: Appearance.font.variableAxes.numbers
                    font.bold: true
                }

                RippleButton {
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    colBackground: Qt.rgba(1, 0.29, 0.29, 0.9)
                    colBackgroundHover: Qt.rgba(1, 0.34, 0.34, 1)
                    colRipple: Qt.rgba(1, 1, 1, 0.25)
                    downAction: () => adapter.dismissLatestNotification()

                    contentItem: MaterialSymbol {
                        text: "close"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Qt.rgba(1, 1, 1, 0.95)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            StyledProgressBar {
                Layout.fillWidth: true
                value: root.progressValue
                valueBarHeight: 10
                highlightColor: Qt.rgba(0.12, 0.49, 0.96, 1)
                trackColor: Qt.rgba(1, 1, 1, 0.14)
            }

            StyledText {
                Layout.fillWidth: true
                text: adapter.latestNotificationBody
                color: Qt.rgba(1, 1, 1, 0.65)
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
    }
}
