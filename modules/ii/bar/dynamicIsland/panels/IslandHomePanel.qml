import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property QtObject adapter

    component CapsuleButton: RippleButton {
        required property string iconName
        required property string labelText
        required property var triggerAction
        property color activeColor: Qt.rgba(1, 1, 1, 0.09)

        implicitHeight: 34
        implicitWidth: labelWidget.implicitWidth + 44
        buttonRadius: Appearance.rounding.full
        colBackground: activeColor
        colBackgroundHover: Qt.rgba(1, 1, 1, 0.16)
        colRipple: Qt.rgba(1, 1, 1, 0.23)
        downAction: () => {
            if (triggerAction)
                triggerAction();
        }

        contentItem: RowLayout {
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                text: iconName
                iconSize: Appearance.font.pixelSize.normal
                color: Qt.rgba(1, 1, 1, 0.92)
            }

            StyledText {
                id: labelWidget
                text: labelText
                color: Qt.rgba(1, 1, 1, 0.92)
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 11

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CapsuleButton {
                iconName: "radio_button_checked"
                labelText: "DynaClip"
                activeColor: Qt.rgba(1, 0.25, 0.25, 0.16)
                triggerAction: () => adapter.toggleMediaControls()
            }

            CapsuleButton {
                iconName: "lens"
                labelText: Translation.tr("Desktop")
                triggerAction: () => adapter.toggleOverview()
            }

            RippleButton {
                implicitWidth: 34
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: Qt.rgba(1, 1, 1, 0.08)
                colBackgroundHover: Qt.rgba(1, 1, 1, 0.14)
                colRipple: Qt.rgba(1, 1, 1, 0.2)
                downAction: () => adapter.toggleRightSidebar()

                contentItem: MaterialSymbol {
                    text: "add"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Qt.rgba(1, 1, 1, 0.9)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.11)

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        implicitHeight: 5
                        color: Qt.rgba(1, 1, 1, 0.08)
                        radius: 6
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: index === 0 ? Translation.tr("Now") : ""
                        color: Qt.rgba(1, 1, 1, 0.46)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Appearance.rounding.full
                color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 8

                    MaterialSymbol {
                        text: "search"
                        iconSize: Appearance.font.pixelSize.large
                        color: Qt.rgba(1, 1, 1, 0.42)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Search")
                        color: Qt.rgba(1, 1, 1, 0.42)
                        elide: Text.ElideRight
                    }
                }
            }

            RippleButton {
                implicitWidth: 34
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: Qt.rgba(1, 1, 1, 0.08)
                colBackgroundHover: Qt.rgba(1, 1, 1, 0.15)
                colRipple: Qt.rgba(1, 1, 1, 0.23)
                downAction: () => adapter.toggleLeftSidebar()

                contentItem: MaterialSymbol {
                    text: "apps"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Qt.rgba(1, 1, 1, 0.9)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            RippleButton {
                implicitWidth: 34
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: Qt.rgba(1, 1, 1, 0.08)
                colBackgroundHover: Qt.rgba(1, 1, 1, 0.15)
                colRipple: Qt.rgba(1, 1, 1, 0.23)
                downAction: () => adapter.toggleRightSidebar()

                contentItem: MaterialSymbol {
                    text: "moving"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Qt.rgba(1, 1, 1, 0.9)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
