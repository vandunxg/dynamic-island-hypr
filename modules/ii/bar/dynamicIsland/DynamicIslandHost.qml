import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.modules.common
import "adapters"
import "models"
import "utils/IslandGeometry.js" as IslandGeometry

PanelWindow {
    id: root

    required property var screenRef
    required property bool parentBarVisible
    required property bool parentBarMustShow

    readonly property var dynamicIslandConfig: Config.options.bar.dynamicIsland
    readonly property bool allowedByBarMode: dynamicIslandConfig.enabled && !Config.options.bar.vertical && !Config.options.bar.bottom
    readonly property bool visibleByBarPolicy: !Config.options.bar.autoHide.enable || parentBarMustShow
    readonly property bool shouldRender: parentBarVisible && !GlobalStates.screenLocked && allowedByBarMode && visibleByBarPolicy
    readonly property real topOffset: (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0) - dynamicIslandConfig.protrusionPx

    screen: screenRef
    visible: shouldRender
    focusable: dynamicIslandSurface.keyboardFocusActive
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell:bar-dynamic-island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: dynamicIslandSurface.keyboardFocusActive
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Math.max(1, topOffset + Math.max(320, IslandGeometry.maxExpandedHeight(dynamicIslandConfig)) + 24)

    mask: Region {
        item: dynamicIslandSurface.inputMask
    }

    IslandStateModel {
        id: stateModel
    }

    IslandServicesAdapter {
        id: adapter
        screen: root.screenRef
        dynamicIslandConfig: root.dynamicIslandConfig
    }

    DynamicIslandController {
        id: controller
        dynamicIslandConfig: root.dynamicIslandConfig
        adapter: adapter
        stateModel: stateModel
        barVisible: root.shouldRender
    }

    DynamicIslandSurface {
        id: dynamicIslandSurface
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topOffset
        controller: controller
        adapter: adapter
        dynamicIslandConfig: root.dynamicIslandConfig
    }

    HyprlandFocusGrab {
        windows: [root]
        active: dynamicIslandSurface.focusGrabActive
        onCleared: dynamicIslandSurface.handleOutsideInteraction()
    }
}
