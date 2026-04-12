import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "panels"
import "utils/IslandGeometry.js" as IslandGeometry

Item {
    id: root

    required property QtObject controller
    required property QtObject adapter
    required property var dynamicIslandConfig

    property alias inputMask: inputMaskItem

    readonly property bool hidden: controller.stateName === "hidden"
    readonly property bool expanded: controller.expanded
    readonly property bool transientEvent: controller.stateName === "transient_event"
    readonly property bool hoverPreview: controller.stateName === "hover_preview"
    readonly property bool hovered: islandHoverHandler.hovered || bridgeHoverHandler.hovered

    readonly property real compactHeight: IslandGeometry.compactHeight(dynamicIslandConfig, Appearance.sizes.baseBarHeight)

    readonly property real targetWidth: {
        if (hidden)
            return 0;
        if (expanded)
            return IslandGeometry.expandedWidthForMode(dynamicIslandConfig, controller.expandedMode);
        if (hoverPreview)
            return dynamicIslandConfig.compactWidth + 26;
        return dynamicIslandConfig.compactWidth;
    }

    readonly property real targetHeight: {
        if (hidden)
            return 0;
        if (expanded)
            return IslandGeometry.expandedHeightForMode(dynamicIslandConfig, controller.expandedMode);
        if (hoverPreview)
            return compactHeight + 2;
        return compactHeight;
    }

    width: targetWidth
    height: targetHeight
    visible: !hidden

    Behavior on width {
        NumberAnimation {
            duration: root.expanded ? dynamicIslandConfig.expandDurationMs : dynamicIslandConfig.collapseDurationMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: root.expanded ? dynamicIslandConfig.expandDurationMs : dynamicIslandConfig.collapseDurationMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }

    Item {
        id: inputMaskItem
        x: surfaceBackground.x
        y: surfaceBackground.y
        width: surfaceBackground.width
        height: surfaceBackground.height + (bridgeArea.visible ? bridgeArea.height : 0)
    }

    Loader {
        anchors.fill: surfaceBackground
        active: dynamicIslandConfig.shadowEnabled
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: surfaceBackground
        }
    }

    Rectangle {
        anchors.fill: surfaceBackground
        anchors.margins: -2
        radius: surfaceBackground.radius + 2
        color: "transparent"
        border.width: root.hovered ? 1 : 0
        border.color: Qt.rgba(0.55, 0.83, 1, 0.28)

        Behavior on border.width {
            NumberAnimation {
                duration: 120
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: surfaceBackground
        anchors.fill: parent
        clip: true
        radius: root.expanded ? dynamicIslandConfig.expandedRadius : dynamicIslandConfig.compactRadius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(0.08, 0.08, 0.09, dynamicIslandConfig.backgroundOpacity)
            }
            GradientStop {
                position: 0.44
                color: Qt.rgba(0.03, 0.03, 0.04, dynamicIslandConfig.backgroundOpacity)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0.02, 0.02, 0.025, Math.min(1, dynamicIslandConfig.backgroundOpacity + 0.02))
            }
        }
        border.width: dynamicIslandConfig.borderWidthPx
        border.color: {
            if (root.expanded)
                return Qt.rgba(1, 1, 1, 0.2);
            if (root.hovered || root.hoverPreview)
                return Qt.rgba(1, 1, 1, 0.23);
            return Qt.rgba(1, 1, 1, 0.12);
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            implicitHeight: Math.max(10, parent.height * 0.28)
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, root.expanded ? 0.08 : 0.13)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
            color: "transparent"
            visible: true
        }

        Rectangle {
            visible: !root.expanded
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 3
            implicitWidth: Math.max(32, parent.width * 0.3)
            implicitHeight: 5
            radius: Appearance.rounding.full
            color: Qt.rgba(1, 1, 1, 0.11)
        }

        Behavior on radius {
            NumberAnimation {
                duration: root.expanded ? dynamicIslandConfig.expandDurationMs : dynamicIslandConfig.collapseDurationMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        MouseArea {
            id: hoverTarget
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: event => {
                if (event.button === Qt.LeftButton) {
                    controller.handlePrimaryClick();
                } else if (event.button === Qt.RightButton) {
                    controller.handleSecondaryClick();
                }
            }
        }

        HoverHandler {
            id: islandHoverHandler
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onHoveredChanged: {
                controller.setCompactHovering(hovered && !controller.expanded);
                controller.setPanelHovering(hovered && controller.expanded);
            }
        }

        Connections {
            target: controller

            function onExpandedChanged() {
                controller.setCompactHovering(islandHoverHandler.hovered && !controller.expanded);
                controller.setPanelHovering(islandHoverHandler.hovered && controller.expanded);
            }
        }

        DynamicIslandCompact {
            id: compactView
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            visible: opacity > 0
            opacity: root.expanded ? 0 : 1
            adapter: root.adapter
            controller: root.controller

            Behavior on opacity {
                NumberAnimation {
                    duration: 110
                }
            }
        }

        Loader {
            id: expandedView
            anchors.fill: parent
            anchors.margins: 2
            active: root.expanded
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            sourceComponent: {
                if (root.transientEvent)
                    return transientPanel;
                if (controller.expandedMode === "media")
                    return mediaPanel;
                if (controller.expandedMode === "message")
                    return messagePanel;
                if (controller.expandedMode === "summary")
                    return summaryPanel;
                if (controller.expandedMode === "notification")
                    return notificationPanel;
                return homePanel;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }
        }
    }

    MouseArea {
        id: bridgeArea
        visible: root.expanded
        acceptedButtons: Qt.NoButton
        anchors.horizontalCenter: surfaceBackground.horizontalCenter
        anchors.top: surfaceBackground.bottom
        width: Math.max(surfaceBackground.width * 0.6, dynamicIslandConfig.compactWidth)
        height: 12
    }

    HoverHandler {
        id: bridgeHoverHandler
        target: bridgeArea
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onHoveredChanged: {
            controller.setBridgeHovering(hovered);
        }
    }

    MaterialSymbol {
        visible: controller.pinned
        anchors {
            right: parent.right
            top: parent.top
            margins: 8
        }
        text: "keep"
        iconSize: Appearance.font.pixelSize.normal
        color: Qt.rgba(1, 1, 1, 0.66)
    }

    Component {
        id: homePanel
        IslandHomePanel {
            adapter: root.adapter
        }
    }

    Component {
        id: mediaPanel
        IslandMediaPanel {
            adapter: root.adapter
        }
    }

    Component {
        id: messagePanel
        IslandMessagePanel {
            adapter: root.adapter
        }
    }

    Component {
        id: summaryPanel
        IslandSummaryPanel {
            adapter: root.adapter
        }
    }

    Component {
        id: notificationPanel
        IslandNotificationPanel {
            adapter: root.adapter
        }
    }

    Component {
        id: transientPanel
        IslandTransientPanel {
            adapter: root.adapter
            transientKind: controller.transientKind
        }
    }
}
