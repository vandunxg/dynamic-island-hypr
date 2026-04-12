import QtQuick

Item {
    id: root

    UserConfig {
        id: userConfig
    }

    property string iconText: ""
    property real progress: -1
    property string customText: ""
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property bool slideFromLyrics: false
    property real transitionProgress: 0
    property bool showCondition: false
    property real hiddenRightPadding: 14

    readonly property bool showProgress: progress >= 0
    readonly property bool showText: progress < 0 && customText !== ""
    readonly property real clampedProgress: Math.max(0, Math.min(1, transitionProgress))
    readonly property real revealProgress: slideFromLyrics ? (1 - clampedProgress) : 1
    readonly property real contentX: slideFromLyrics ? (width + hiddenRightPadding) * clampedProgress : 0

    anchors.fill: parent
    clip: true
    opacity: showCondition ? revealProgress : 0

    Behavior on opacity {
        enabled: !slideFromLyrics

        NumberAnimation {
            duration: showCondition ? 180 : 120
            easing.type: Easing.InOutQuad
        }
    }

    Item {
        x: contentX
        width: parent.width
        height: parent.height
        visible: showProgress

        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: iconText
                color: "#f4f5f7"
                font.pixelSize: 16
                font.family: iconFontFamily
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Math.round(progress * 100) + "%"
                color: "#f4f5f7"
                font.pixelSize: 17
                font.family: heroFontFamily
                font.weight: Font.Bold
                font.letterSpacing: -0.25
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    property real progressValue: Math.max(0, Math.min(1, progress))

                    onProgressValueChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        const size = Math.min(width, height);
                        const lineWidth = 2.8;
                        const center = size / 2;
                        const radius = (size - lineWidth) / 2 - 0.5;
                        const startAngle = -Math.PI / 2;
                        const endAngle = startAngle + (Math.PI * 2 * progressValue);

                        ctx.clearRect(0, 0, width, height);
                        ctx.lineCap = "round";
                        ctx.lineWidth = lineWidth;

                        ctx.strokeStyle = "rgba(255, 255, 255, 0.16)";
                        ctx.beginPath();
                        ctx.arc(center, center, radius, 0, Math.PI * 2, false);
                        ctx.stroke();

                        ctx.strokeStyle = "#78d8ff";
                        ctx.beginPath();
                        ctx.arc(center, center, radius, startAngle, endAngle, false);
                        ctx.stroke();
                    }
                }
            }
        }
    }

    Item {
        x: contentX
        width: parent.width
        height: parent.height
        visible: showText

        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: iconText
                color: "#f4f5f7"
                font.pixelSize: 16
                font.family: iconFontFamily
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: customText
                color: "#f4f5f7"
                font.pixelSize: 14
                font.family: textFontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: -0.1
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
