import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    required property QtObject adapter

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: adapter.summaryTime
                    color: Qt.rgba(1, 1, 1, 0.97)
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.family: Appearance.font.family.numbers
                    font.variableAxes: Appearance.font.variableAxes.numbers
                }

                StyledText {
                    text: adapter.summaryDate
                    color: Qt.rgba(1, 1, 1, 0.68)
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }

            Rectangle {
                implicitWidth: 44
                implicitHeight: 44
                radius: Appearance.rounding.full
                color: Qt.rgba(1, 1, 1, 0.1)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "today"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Qt.rgba(1, 1, 1, 0.88)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 78
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 1

                    StyledText {
                        text: Translation.tr("Weather")
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }

                    StyledText {
                        text: adapter.summaryWeatherEnabled ? `${adapter.summaryWeatherTemp} - ${adapter.summaryWeatherCity}` : Translation.tr("Disabled")
                        color: Qt.rgba(1, 1, 1, 0.9)
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: adapter.summaryWeatherEnabled ? adapter.summaryWeatherWind : ""
                        color: Qt.rgba(1, 1, 1, 0.62)
                        font.pixelSize: Appearance.font.pixelSize.small
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 78
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 1

                    StyledText {
                        text: Translation.tr("Status")
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }

                    StyledText {
                        text: adapter.hasUnreadNotification ? Translation.tr("%1 unread notifications").arg(Notifications.unread) : Translation.tr("No pending alerts")
                        color: Qt.rgba(1, 1, 1, 0.9)
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: adapter.fullscreen ? Translation.tr("Fullscreen app active") : Translation.tr("Normal workspace")
                        color: Qt.rgba(1, 1, 1, 0.62)
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }
}
