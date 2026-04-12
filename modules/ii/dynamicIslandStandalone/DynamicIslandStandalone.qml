import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import "../bar/dynamicIsland" as DynamicIsland

Scope {
    id: root

    readonly property var dynamicIslandConfig: Config.options.bar.dynamicIsland
    readonly property bool enabledByConfig: !!dynamicIslandConfig.enabled
    readonly property bool active: enabledByConfig && GlobalStates.dynamicIslandStandaloneOpen && !GlobalStates.screenLocked

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        LazyLoader {
            id: islandLoader
            active: root.active

            required property ShellScreen modelData

            component: DynamicIsland.StandaloneDynamicIslandHost {
                screenRef: islandLoader.modelData
            }
        }
    }

    IpcHandler {
        target: "dynamicIslandStandalone"

        function toggle(): void {
            GlobalStates.dynamicIslandStandaloneOpen = !GlobalStates.dynamicIslandStandaloneOpen;
        }

        function open(): void {
            GlobalStates.dynamicIslandStandaloneOpen = true;
        }

        function close(): void {
            GlobalStates.dynamicIslandStandaloneOpen = false;
        }

        function status(): var {
            return {
                enabledByConfig: root.enabledByConfig,
                open: GlobalStates.dynamicIslandStandaloneOpen,
                active: root.active
            };
        }
    }
}
