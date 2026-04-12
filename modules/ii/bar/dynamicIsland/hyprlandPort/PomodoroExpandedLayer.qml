import QtQuick
import qs.services

Item {
    id: root

    signal controlPressed()

    UserConfig {
        id: userConfig
    }

    property bool showCondition: false
    property int secondsLeft: 0
    property int lapDuration: 1
    property bool isRunning: false
    property bool isBreak: false
    property bool isLongBreak: false
    property int cycle: 0
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.timeFontFamily
    property real transitionProgress: 1

    readonly property real revealProgress: showCondition ? 1 : 0
    readonly property real normalizedProgress: {
        if (lapDuration <= 0)
            return 0;
        return Math.max(0, Math.min(1, secondsLeft / lapDuration));
    }
    readonly property color accentColor: isBreak ? "#ff9745" : "#ff7f57"
    readonly property color accentDimColor: isBreak ? "#6a4833" : "#6f3e36"
    readonly property string statusText: isLongBreak ? "Long break" : (isBreak ? "Break" : "Focus")

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatCountdown(value) {
        const safe = Math.max(0, Math.floor(Number(value) || 0));
        const minutes = Math.floor(safe / 60);
        const seconds = safe % 60;
        return pad2(minutes) + ":" + pad2(seconds);
    }

    anchors.fill: parent
    anchors.margins: 10
    opacity: revealProgress
    visible: opacity > 0
    x: (width + 24) * (1 - transitionProgress)

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

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "#0f1014"
        border.width: 1
        border.color: "#24262e"

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Item {
            width: 74
            height: 74
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#171a21"
                border.width: 1
                border.color: root.accentDimColor
            }

            Canvas {
                id: expandedRing

                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d");
                    const center = width / 2;
                    const radius = Math.max(0, center - 3.5);
                    const start = -Math.PI * 0.5;
                    const end = start + Math.PI * 2 * root.normalizedProgress;

                    ctx.clearRect(0, 0, width, height);
                    ctx.beginPath();
                    ctx.lineWidth = 3.4;
                    ctx.strokeStyle = root.accentColor;
                    ctx.arc(center, center, radius, start, end, false);
                    ctx.stroke();
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                Connections {
                    target: root
                    function onSecondsLeftChanged() { expandedRing.requestPaint(); }
                    function onLapDurationChanged() { expandedRing.requestPaint(); }
                    function onIsBreakChanged() { expandedRing.requestPaint(); }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.statusText === "Focus" ? "F" : "B"
                color: "#f5d4bf"
                font.pixelSize: 16
                font.family: root.heroFontFamily
                font.weight: Font.DemiBold
            }
        }

        Column {
            width: parent.width - 74 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: root.formatCountdown(root.secondsLeft)
                color: root.accentColor
                font.pixelSize: 34
                font.family: root.heroFontFamily
                font.weight: Font.Bold
                font.letterSpacing: -0.4
            }

            Row {
                spacing: 8

                Rectangle {
                    width: 74
                    height: 20
                    radius: 10
                    color: "#181d27"
                    border.width: 1
                    border.color: root.accentDimColor

                    Text {
                        anchors.centerIn: parent
                        text: root.statusText
                        color: "#f4d2be"
                        font.pixelSize: 9
                        font.family: root.textFontFamily
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    width: 44
                    height: 20
                    radius: 10
                    color: "#141821"
                    border.width: 1
                    border.color: "#35435a"

                    Text {
                        anchors.centerIn: parent
                        text: "#" + String(root.cycle + 1)
                        color: "#c8d7f1"
                        font.pixelSize: 9
                        font.family: root.textFontFamily
                        font.weight: Font.DemiBold
                    }
                }
            }

            Row {
                spacing: 8

                Rectangle {
                    id: playButton

                    width: 76
                    height: 26
                    radius: 13
                    color: playMouse.pressed
                        ? "#2f6d42"
                        : (playMouse.containsMouse ? "#2a633d" : "#245636")
                    border.width: 1
                    border.color: "#4f9f69"

                    Text {
                        anchors.centerIn: parent
                        text: root.isRunning ? "Pause" : "Start"
                        color: "#dcf7e5"
                        font.pixelSize: 10
                        font.family: root.textFontFamily
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: playMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onPressed: (mouse) => {
                            root.controlPressed();
                            mouse.accepted = true;
                        }

                        onClicked: TimerService.togglePomodoro()
                    }
                }

                Rectangle {
                    id: resetButton

                    width: 66
                    height: 26
                    radius: 13
                    color: resetMouse.pressed
                        ? "#6c3135"
                        : (resetMouse.containsMouse ? "#5d2b2f" : "#51262a")
                    border.width: 1
                    border.color: "#b15f68"

                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        color: "#ffd8de"
                        font.pixelSize: 10
                        font.family: root.textFontFamily
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: resetMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onPressed: (mouse) => {
                            root.controlPressed();
                            mouse.accepted = true;
                        }

                        onClicked: TimerService.resetPomodoro()
                    }
                }
            }
        }
    }
}
