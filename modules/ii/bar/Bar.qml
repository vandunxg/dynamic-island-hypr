import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "dynamicIsland" as DynamicIsland

Scope {
    id: bar
    property bool showBarBackground: Config.options.bar.showBackground
    readonly property bool dynamicIslandOnlyMode: Config.options.bar.dynamicIsland.enabled && !Config.options.bar.vertical && !Config.options.bar.bottom
    property bool reopenAfterModeSwitch: false

    function refreshModeSwitch(forceOpen) {
        reopenAfterModeSwitch = forceOpen === true ? true : GlobalStates.barOpen;
        GlobalStates.barOpen = false;
        modeSwitchRefreshTimer.restart();
    }

    Timer {
        id: modeSwitchRefreshTimer
        interval: 1
        repeat: false
        onTriggered: {
            GlobalStates.barOpen = bar.reopenAfterModeSwitch;
        }
    }

    Variants {
        // For each monitor
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData
            component: PanelWindow { // Bar window
                id: barRoot
                screen: barLoader.modelData
                readonly property bool dynamicIslandOnlyMode: bar.dynamicIslandOnlyMode

                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: {
                        barRoot.superShow = true
                    }
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }
                property bool superShow: false
                property bool mustShow: dynamicIslandOnlyMode || hoverRegion.containsMouse || superShow
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: dynamicIslandOnlyMode ? 0 : ((Config?.options.bar.autoHide.enable && (!mustShow || !Config?.options.bar.autoHide.pushWindows)) ? 0 :
                    Appearance.sizes.baseBarHeight + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0))
                WlrLayershell.namespace: "quickshell:bar"
                implicitHeight: dynamicIslandOnlyMode ? 1 : (Appearance.sizes.barHeight + Appearance.rounding.screenRounding)
                mask: Region {
                    item: dynamicIslandOnlyMode ? null : hoverMaskRegion
                }
                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    right: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                    bottom: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                }

                MouseArea  {
                    id: hoverRegion
                    enabled: !barRoot.dynamicIslandOnlyMode
                    hoverEnabled: true
                    anchors {
                        fill: parent
                        rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * 1
                        bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * 1
                    }

                    Item {
                        id: hoverMaskRegion
                        anchors {
                            fill: barContent
                            topMargin: -Config.options.bar.autoHide.hoverRegionWidth
                            bottomMargin: -Config.options.bar.autoHide.hoverRegionWidth
                        }
                    }

                    BarContent {
                        id: barContent
                        visible: !barRoot.dynamicIslandOnlyMode
                        
                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            right: parent.right
                            left: parent.left
                            top: parent.top
                            bottom: undefined
                            topMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : 0
                            bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                            rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                        }
                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: parent.bottom
                                }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.bottomMargin: (Config?.options.bar.autoHide.enable && !mustShow) ? -Appearance.sizes.barHeight : 0
                            }
                        }
                    }

                    // Round decorators
                    Loader {
                        id: roundDecorators
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: barContent.bottom
                            bottom: undefined
                        }
                        height: Appearance.rounding.screenRounding
                        active: !barRoot.dynamicIslandOnlyMode && showBarBackground && Config.options.bar.cornerStyle === 0 // Hug

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: roundDecorators
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: barContent.top
                                }
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding
                            RoundCorner {
                                id: leftCorner
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                }

                                implicitSize: Appearance.rounding.screenRounding
                                color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                                corner: RoundCorner.CornerEnum.TopLeft
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        leftCorner.corner: RoundCorner.CornerEnum.BottomLeft
                                    }
                                }
                            }
                            RoundCorner {
                                id: rightCorner
                                anchors {
                                    right: parent.right
                                    top: !Config.options.bar.bottom ? parent.top : undefined
                                    bottom: Config.options.bar.bottom ? parent.bottom : undefined
                                }
                                implicitSize: Appearance.rounding.screenRounding
                                color: showBarBackground ? Appearance.colors.colLayer0 : "transparent"

                                corner: RoundCorner.CornerEnum.TopRight
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        rightCorner.corner: RoundCorner.CornerEnum.BottomRight
                                    }
                                }
                            }
                        }
                    }
                }

                DynamicIsland.DynamicIslandHost {
                    screenRef: barRoot.screen
                    parentBarVisible: barLoader.active
                    parentBarMustShow: barRoot.dynamicIslandOnlyMode ? true : barRoot.mustShow
                }

            }
        }

    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    IpcHandler {
        target: "dynamicIsland"

        function toggle(): void {
            Config.options.bar.dynamicIsland.enabled = !Config.options.bar.dynamicIsland.enabled;
            if (!Config.options.bar.dynamicIsland.enabled)
                GlobalStates.dynamicIslandOverviewOpen = false;
            bar.refreshModeSwitch(true);
        }

        function enable(): void {
            Config.options.bar.dynamicIsland.enabled = true;
            bar.refreshModeSwitch(true);
        }

        function disable(): void {
            Config.options.bar.dynamicIsland.enabled = false;
            GlobalStates.dynamicIslandOverviewOpen = false;
            bar.refreshModeSwitch(true);
        }

        function status(): var {
            return {
                dynamicEnabled: Config.options.bar.dynamicIsland.enabled,
                dynamicOnlyMode: bar.dynamicIslandOnlyMode,
                dynamicOverviewOpen: GlobalStates.dynamicIslandOverviewOpen,
                barOpen: GlobalStates.barOpen,
                vertical: Config.options.bar.vertical,
                bottom: Config.options.bar.bottom
            };
        }
    }

    IpcHandler {
        target: "dynamicIslandOverview"

        function toggle(): void {
            GlobalStates.dynamicIslandOverviewOpen = !GlobalStates.dynamicIslandOverviewOpen;
        }

        function open(): void {
            GlobalStates.dynamicIslandOverviewOpen = true;
        }

        function close(): void {
            GlobalStates.dynamicIslandOverviewOpen = false;
        }

        function status(): var {
            return {
                open: GlobalStates.dynamicIslandOverviewOpen,
                dynamicEnabled: Config.options.bar.dynamicIsland.enabled,
                dynamicOnlyMode: bar.dynamicIslandOnlyMode
            };
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
