import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property QtObject adapter
    required property string transientKind

    readonly property bool brightnessMode: transientKind === "brightness"
    readonly property int valuePercent: brightnessMode ? adapter.brightnessPercent : adapter.volumePercent
    readonly property string iconName: {
        if (brightnessMode)
            return "light_mode";
        return adapter.volumeMuted ? "volume_off" : "volume_up";
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: Appearance.rounding.full
            color: Qt.rgba(1, 1, 1, 0.12)

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.iconName
                iconSize: Appearance.font.pixelSize.large
                color: Qt.rgba(1, 1, 1, 0.94)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: brightnessMode ? Translation.tr("Brightness") : Translation.tr("Volume")
                color: Qt.rgba(1, 1, 1, 0.78)
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledProgressBar {
                Layout.fillWidth: true
                value: root.valuePercent / 100
                highlightColor: Qt.rgba(0.31, 0.63, 1, 1)
                trackColor: Qt.rgba(1, 1, 1, 0.2)
                wavy: !brightnessMode
                animateWave: !brightnessMode
            }
        }

        StyledText {
            text: `${root.valuePercent}%`
            color: Qt.rgba(1, 1, 1, 0.9)
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            font.variableAxes: Appearance.font.variableAxes.numbers
        }
    }
}
