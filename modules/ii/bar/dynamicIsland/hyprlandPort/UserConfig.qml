import QtQuick
import qs.modules.common

QtObject {
    id: userConfig

    property string wallpaperPath: Config.options.background.wallpaperPath
    property real workspaceOverviewWindowRadius: 12
    property string iconFontFamily: Appearance.font.family.iconNerd
    property string textFontFamily: Appearance.font.family.main
    property string heroFontFamily: Appearance.font.family.main
    property string timeFontFamily: Appearance.font.family.numbers

    property int overviewCloseKey: Qt.Key_Escape
    property int overviewPreviousWorkspaceKey: Qt.Key_Left
    property int overviewNextWorkspaceKey: Qt.Key_Right

    property bool overviewGlobalShortcutEnabled: false
    property string overviewGlobalShortcutAppid: "quickshell"
    property string overviewGlobalShortcutName: "dynamic-island-overview"
    property string overviewGlobalShortcutDescription: "Toggle Dynamic Island workspace overview"
    property string overviewGlobalShortcutTriggerDescription: "Super+Tab"

    property int workspaceOverviewWorkspaceActivateButton: 1
    property int workspaceOverviewWindowDragButton: 1
    property int workspaceOverviewWindowFocusButton: 1
    property int workspaceOverviewWindowCloseButton: 3

    property int dynamicIslandSwipeButton: 1
    property int dynamicIslandPrimaryButton: 1
    property string dynamicIslandPrimaryAction: "toggleExpandedPlayer"
    property int dynamicIslandSecondaryButton: 3
    property string dynamicIslandSecondaryAction: "toggleControlCenter"

    property var controlCenterActions: ([
        { icon: "󰍉", action: "overview" },
        { icon: "󰖯", action: "leftSidebar" },
        { icon: "", action: "rightSidebar" },
        { icon: "󰝚", action: "mediaControls" }
    ])

    property var controlCenterIcons: ({
        "charging": "",
        "brightness": "󰃟",
        "volume": "󰕾"
    })

    property var statusIcons: ({
        "default": "🎧",
        "notification": "",
        "volume": "󰕾",
        "mute": "󰝟",
        "brightnessLow": "󰃞",
        "brightnessMedium": "󰃟",
        "brightnessHigh": "󰃠",
        "charging": "",
        "discharging": "",
        "capsLockOn": "",
        "capsLockOff": "",
        "bluetooth": "󰋋"
    })

    function mouseButton(button) {
        switch (button) {
        case 1:
            return Qt.LeftButton;
        case 2:
            return Qt.MiddleButton;
        case 3:
            return Qt.RightButton;
        default:
            return typeof button === "number" ? button : Qt.NoButton;
        }
    }

    function mouseButtonsMask(buttons) {
        if (buttons === undefined || buttons === null)
            return Qt.NoButton;

        if (Array.isArray(buttons)) {
            let mask = Qt.NoButton;
            for (let index = 0; index < buttons.length; index++)
                mask |= mouseButton(buttons[index]);
            return mask;
        }

        return mouseButton(buttons);
    }
}
