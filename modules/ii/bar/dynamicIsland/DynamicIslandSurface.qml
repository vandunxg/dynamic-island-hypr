import QtQuick
import "hyprlandPort" as HyprlandPort

Item {
    id: root

    required property QtObject controller
    required property QtObject adapter
    required property var dynamicIslandConfig

    readonly property bool useHyprlandPort: (dynamicIslandConfig.preset ?? "hyprlandPort") === "hyprlandPort"

    property var inputMask: surfaceLoader.item?.inputMask ?? null
    readonly property bool focusGrabActive: useHyprlandPort
        ? (surfaceLoader.item?.focusGrabActive ?? false)
        : (controller.expanded && !controller.pinned)
    readonly property bool keyboardFocusActive: useHyprlandPort
        ? (surfaceLoader.item?.keyboardFocusActive ?? false)
        : false

    function handleOutsideInteraction() {
        if (useHyprlandPort && surfaceLoader.item && surfaceLoader.item.handleOutsideInteraction) {
            surfaceLoader.item.handleOutsideInteraction();
            return;
        }
        controller.onOutsideInteraction();
    }

    Loader {
        id: surfaceLoader
        anchors.fill: parent
        sourceComponent: root.useHyprlandPort ? hyprlandPortSurface : classicSurface
    }

    Component {
        id: hyprlandPortSurface

        HyprlandPort.PortDynamicIslandScene {
            controller: root.controller
            adapter: root.adapter
            dynamicIslandConfig: root.dynamicIslandConfig
        }
    }

    Component {
        id: classicSurface

        DynamicIslandSurfaceClassic {
            controller: root.controller
            adapter: root.adapter
            dynamicIslandConfig: root.dynamicIslandConfig
        }
    }
}
