import QtQuick
import Quickshell

Item {
    UserConfig {
        id: userConfig
    }

    property bool showCondition: false
    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string iconText: "notifications"
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily

    readonly property string displayAppName: appName !== "" ? appName : "Notification"
    readonly property string appInitial: {
        const trimmed = displayAppName.trim();
        return trimmed !== "" ? trimmed.charAt(0).toUpperCase() : "N";
    }
    readonly property string primaryText: {
        if (summary !== "")
            return summary;
        if (body !== "")
            return body;
        return "New notification";
    }
    readonly property string secondaryText: {
        if (summary !== "" && body !== "" && body !== summary)
            return body;
        return "";
    }
    readonly property bool compactUltra: true
    readonly property bool hasSecondaryLine: !compactUltra && secondaryText !== ""
    readonly property color accentColor: "#7fb5ff"

    readonly property real minimumWidth: 272
    readonly property real maximumWidth: 404
    readonly property real iconSlotWidth: compactUltra ? 28 : 32
    readonly property real contentSpacing: compactUltra ? 10 : 11
    readonly property real horizontalPadding: compactUltra ? 12 : 13
    readonly property real verticalPadding: compactUltra ? 7 : 8
    readonly property real textBlockWidthAtMaximum: maximumWidth - horizontalPadding * 2 - iconSlotWidth - contentSpacing
    readonly property real widestTextLine: compactUltra
        ? Math.max(appMetrics.advanceWidth, primaryMetrics.advanceWidth)
        : Math.max(appMetrics.advanceWidth, Math.max(primaryMetrics.advanceWidth, secondaryMetrics.advanceWidth))
    readonly property real preferredWidth: Math.max(
        minimumWidth,
        Math.min(maximumWidth, widestTextLine + iconSlotWidth + contentSpacing + horizontalPadding * 2 + 2)
    )
    readonly property real preferredHeight: compactUltra ? 56 : (hasSecondaryLine ? 66 : 58)
    readonly property string resolvedAppIcon: {
        const source = String(appIcon || "").trim();
        if (source !== "") {
            if (source.startsWith("/")
                    || source.startsWith("file://")
                    || source.startsWith("qrc:")
                    || source.startsWith("image://"))
                return source;
            return Quickshell.iconPath(source, "dialog-information");
        }

        return Quickshell.iconPath(displayAppName.toLowerCase(), "dialog-information");
    }

    anchors.fill: parent
    anchors.margins: 0
    opacity: showCondition ? 1 : 0
    y: showCondition ? 0 : 2
    clip: true

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 280 : 140
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: showCondition ? 220 : 120
            easing.type: Easing.OutCubic
        }
    }

    TextMetrics {
        id: appMetrics

        font.family: textFontFamily
        font.pixelSize: 9
        font.weight: Font.DemiBold
        text: displayAppName
    }

    TextMetrics {
        id: primaryMetrics

        font.family: textFontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        text: primaryText
    }

    TextMetrics {
        id: secondaryMetrics

        font.family: textFontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        text: secondaryText
    }

    Rectangle {
        anchors.fill: parent
        radius: 13
        color: "#0a111a"
        border.width: 1
        border.color: "#1c2a3b"
        opacity: 0.58
    }

    Rectangle {
        anchors.fill: parent
        radius: 13
        color: "transparent"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#1d2c3d"
            }
            GradientStop {
                position: 0.35
                color: "#0f1824"
            }
            GradientStop {
                position: 1
                color: "#00000000"
            }
        }
        opacity: 0.18
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: horizontalPadding
        anchors.rightMargin: horizontalPadding
        anchors.topMargin: verticalPadding
        anchors.bottomMargin: verticalPadding
        spacing: contentSpacing
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            radius: 1
            color: accentColor
            opacity: 0.85
        }

        Rectangle {
            width: iconSlotWidth
            height: iconSlotWidth
            radius: compactUltra ? 8 : 9
            anchors.verticalCenter: parent.verticalCenter
            color: "#101a27"
            border.width: 1
            border.color: "#2a3a50"

            Image {
                id: appIconImage

                anchors.centerIn: parent
                width: 18
                height: 18
                source: resolvedAppIcon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !appIconImage.visible && iconText !== ""
                text: iconText
                color: "#f2f6fb"
                font.pixelSize: compactUltra ? 14 : 15
                font.family: iconFontFamily
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                anchors.centerIn: parent
                visible: !appIconImage.visible && iconText === ""
                text: appInitial
                color: "#f2f6fb"
                font.pixelSize: compactUltra ? 11 : 12
                font.family: textFontFamily
                font.weight: Font.Bold
            }
        }

        Column {
            width: parent.width - 2 - iconSlotWidth - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: compactUltra ? 0 : (hasSecondaryLine ? 1 : 2)

            Text {
                width: parent.width
                text: displayAppName
                color: "#8fa6c2"
                font.pixelSize: compactUltra ? 8 : 9
                font.family: textFontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: 0.12
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
            }

            Text {
                width: parent.width
                text: primaryText
                color: "#f5f8fc"
                font.pixelSize: compactUltra ? 12 : 13
                font.family: textFontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: -0.12
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
            }

            Text {
                width: parent.width
                visible: hasSecondaryLine
                text: secondaryText
                color: "#adc0d6"
                font.pixelSize: 10
                font.family: textFontFamily
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
            }
        }
    }
}
