import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property QtObject adapter

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            implicitWidth: 48
            implicitHeight: 48
            radius: Appearance.rounding.full
            color: Qt.rgba(1, 1, 1, 0.12)

            StyledText {
                anchors.centerIn: parent
                text: adapter.latestNotificationAppName.length > 0 ? adapter.latestNotificationAppName.slice(0, 1).toUpperCase() : "M"
                color: Qt.rgba(1, 1, 1, 0.96)
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            StyledText {
                Layout.fillWidth: true
                text: adapter.latestNotificationAppName
                color: Qt.rgba(1, 1, 1, 0.98)
                font.pixelSize: Appearance.font.pixelSize.normal
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: adapter.latestNotificationBody || adapter.latestNotificationTitle
                color: Qt.rgba(1, 1, 1, 0.72)
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Appearance.rounding.full
                color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Quick reply")
                        color: Qt.rgba(1, 1, 1, 0.46)
                    }

                    RippleButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        buttonRadius: Appearance.rounding.full
                        colBackground: Qt.rgba(1, 1, 1, 0.16)
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.2)
                        colRipple: Qt.rgba(1, 1, 1, 0.26)
                        downAction: () => adapter.openNotificationCenter()

                        contentItem: MaterialSymbol {
                            text: "arrow_upward"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Qt.rgba(1, 1, 1, 0.94)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
