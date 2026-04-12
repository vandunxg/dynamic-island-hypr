import QtQuick

Item {
    id: root

    property bool showCondition: false
    property int secondsLeft: 0
    property int lapDuration: 1
    property bool isRunning: false
    property bool isBreak: false
    property bool isLongBreak: false
    property string textFontFamily: "Sans Serif"
    property string heroFontFamily: textFontFamily
    property real transitionProgress: 1

    readonly property real revealProgress: showCondition ? 1 : 0
    readonly property real normalizedProgress: {
        if (lapDuration <= 0)
            return 0;
        return Math.max(0, Math.min(1, secondsLeft / lapDuration));
    }
    property real progressAnimated: normalizedProgress
    property real timePulse: 0
    property real timeShift: 0
    property string displayedTime: formatCountdown(secondsLeft)
    property string pendingTime: displayedTime
    readonly property color accentColor: isBreak ? "#ffad57" : "#ff9238"

    onNormalizedProgressChanged: progressAnimated = normalizedProgress

    onSecondsLeftChanged: {
        const next = formatCountdown(secondsLeft);
        if (next === displayedTime)
            return;

        pendingTime = next;
        if (!showCondition) {
            displayedTime = next;
            timePulse = 0;
            timeShift = 0;
            return;
        }

        timeTickAnim.restart();
    }

    onShowConditionChanged: {
        if (showCondition) {
            displayedTime = formatCountdown(secondsLeft);
            pendingTime = displayedTime;
            timePulse = 0;
            timeShift = 0;
        }
    }

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
    anchors.margins: 5
    opacity: revealProgress
    x: width * (1 - transitionProgress)

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 150
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    Behavior on progressAnimated {
        NumberAnimation {
            duration: 360
            easing.type: Easing.InOutQuad
        }
    }

    SequentialAnimation {
        id: timeTickAnim

        running: false

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "timePulse"
                to: 0.22
                duration: 110
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: root
                property: "timeShift"
                to: 2
                duration: 110
                easing.type: Easing.InQuad
            }
        }

        ScriptAction {
            script: {
                root.displayedTime = root.pendingTime;
                root.timeShift = -2;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "timePulse"
                to: 0
                duration: 260
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "timeShift"
                to: 0
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: timerIcon

        width: 24
        height: 24
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.verticalCenter: parent.verticalCenter

        property real handRotation: -35
        property real glowPulse: 0

        SequentialAnimation on handRotation {
            running: root.showCondition && root.isRunning
            loops: Animation.Infinite

            NumberAnimation {
                from: -35
                to: 325
                duration: 1750
                easing.type: Easing.Linear
            }
        }

        SequentialAnimation on glowPulse {
            running: root.showCondition
            loops: Animation.Infinite

            NumberAnimation {
                from: 0
                to: 1
                duration: 1300
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                from: 1
                to: 0
                duration: 1300
                easing.type: Easing.InOutSine
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#121418"
            border.width: 1
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45 + timerIcon.glowPulse * 0.25)
        }

        Canvas {
            id: compactRing

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d");
                const center = width / 2;
                const radius = Math.max(0, center - 2.7);
                const start = -Math.PI * 0.5;
                const end = start + Math.PI * 2 * root.progressAnimated;

                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.lineWidth = 2.2;
                ctx.strokeStyle = root.accentColor;
                ctx.arc(center, center, radius, start, end, false);
                ctx.stroke();
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: root
                function onSecondsLeftChanged() { compactRing.requestPaint(); }
                function onLapDurationChanged() { compactRing.requestPaint(); }
                function onIsBreakChanged() { compactRing.requestPaint(); }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 8
            radius: 1
            color: root.accentColor
            antialiasing: true
            rotation: timerIcon.handRotation
            transformOrigin: Item.Bottom
            y: -Math.round(height / 2)
        }

        Rectangle {
            anchors.centerIn: parent
            width: 3
            height: 3
            radius: 1.5
            color: root.accentColor
        }
    }

    Text {
        anchors.left: timerIcon.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.displayedTime
        color: root.accentColor
        font.pixelSize: 18
        font.family: root.heroFontFamily
        font.weight: Font.Bold
        font.letterSpacing: -0.35
        elide: Text.ElideRight
        y: root.timeShift
        scale: 1 + root.timePulse * 0.02
        opacity: 0.9 + root.timePulse * 0.1
    }
}
