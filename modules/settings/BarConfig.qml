import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }
    
    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "pill"
        title: Translation.tr("Dynamic island")

        ConfigSwitch {
            buttonIcon: "toggle_on"
            text: Translation.tr("Enable")
            checked: Config.options.bar.dynamicIsland.enabled
            onCheckedChanged: {
                Config.options.bar.dynamicIsland.enabled = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Preset")

            ConfigSelectionArray {
                currentValue: Config.options.bar.dynamicIsland.preset
                onSelected: newValue => {
                    Config.options.bar.dynamicIsland.preset = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Hyprland port"),
                        icon: "animation",
                        value: "hyprlandPort"
                    },
                    {
                        displayName: Translation.tr("Custom panels"),
                        icon: "dashboard",
                        value: "classic"
                    }
                ]
            }
        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pin on click")
                checked: Config.options.bar.dynamicIsland.pinOnClick
                onCheckedChanged: {
                    Config.options.bar.dynamicIsland.pinOnClick = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "layers"
                text: Translation.tr("Allow center overlap")
                checked: Config.options.bar.dynamicIsland.allowCenterOverlap
                onCheckedChanged: {
                    Config.options.bar.dynamicIsland.allowCenterOverlap = checked;
                }
            }
        }

        ConfigRow {
            uniform: true

            ConfigSpinBox {
                icon: "width"
                text: Translation.tr("Compact width")
                value: Config.options.bar.dynamicIsland.compactWidth
                from: 96
                to: 220
                stepSize: 2
                onValueChanged: {
                    Config.options.bar.dynamicIsland.compactWidth = value;
                }
            }

            ConfigSpinBox {
                icon: "arrow_drop_up"
                text: Translation.tr("Protrusion (px)")
                value: Config.options.bar.dynamicIsland.protrusionPx
                from: 0
                to: 8
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.dynamicIsland.protrusionPx = value;
                }
            }
        }

        ConfigRow {
            uniform: true

            ConfigSpinBox {
                icon: "unfold_more"
                text: Translation.tr("Reserve gap")
                value: Config.options.bar.dynamicIsland.reserveGapPx
                from: 0
                to: 60
                stepSize: 2
                onValueChanged: {
                    Config.options.bar.dynamicIsland.reserveGapPx = value;
                }
            }

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Background opacity (%)")
                value: Math.round(Config.options.bar.dynamicIsland.backgroundOpacity * 100)
                from: 70
                to: 100
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.dynamicIsland.backgroundOpacity = value / 100;
                }
            }
        }

        ConfigRow {
            uniform: true

            ConfigSpinBox {
                icon: "timer"
                text: Translation.tr("Hover open delay (ms)")
                value: Config.options.bar.dynamicIsland.hoverOpenDelayMs
                from: 80
                to: 300
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.dynamicIsland.hoverOpenDelayMs = value;
                }
            }

            ConfigSpinBox {
                icon: "timer_off"
                text: Translation.tr("Hover close delay (ms)")
                value: Config.options.bar.dynamicIsland.hoverCloseDelayMs
                from: 120
                to: 500
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.dynamicIsland.hoverCloseDelayMs = value;
                }
            }
        }

        ConfigRow {
            uniform: true

            ConfigSpinBox {
                icon: "resize"
                text: Translation.tr("Media width")
                value: Config.options.bar.dynamicIsland.sizes.mediaWidth
                from: 520
                to: 900
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.dynamicIsland.sizes.mediaWidth = value;
                }
            }

            ConfigSpinBox {
                icon: "height"
                text: Translation.tr("Media height")
                value: Config.options.bar.dynamicIsland.sizes.mediaHeight
                from: 160
                to: 360
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.dynamicIsland.sizes.mediaHeight = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Default mode")

            ConfigSelectionArray {
                currentValue: Config.options.bar.dynamicIsland.defaultMode
                onSelected: newValue => {
                    Config.options.bar.dynamicIsland.defaultMode = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Home"),
                        icon: "dashboard",
                        value: "home"
                    },
                    {
                        displayName: Translation.tr("Media"),
                        icon: "music_note",
                        value: "media"
                    },
                    {
                        displayName: Translation.tr("Message"),
                        icon: "chat",
                        value: "message"
                    },
                    {
                        displayName: Translation.tr("Summary"),
                        icon: "today",
                        value: "summary"
                    },
                    {
                        displayName: Translation.tr("Notification"),
                        icon: "notifications",
                        value: "notification"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Monitor policy")

            ConfigSelectionArray {
                currentValue: Config.options.bar.dynamicIsland.preferredMonitor
                onSelected: newValue => {
                    Config.options.bar.dynamicIsland.preferredMonitor = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Active monitor"),
                        icon: "select_window_2",
                        value: "active"
                    },
                    {
                        displayName: Translation.tr("All bar monitors"),
                        icon: "view_compact_alt",
                        value: "all"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Modules")

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "dashboard"
                    text: Translation.tr("Home")
                    checked: Config.options.bar.dynamicIsland.modules.home
                    onCheckedChanged: {
                        Config.options.bar.dynamicIsland.modules.home = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr("Media")
                    checked: Config.options.bar.dynamicIsland.modules.media
                    onCheckedChanged: {
                        Config.options.bar.dynamicIsland.modules.media = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "chat"
                    text: Translation.tr("Message")
                    checked: Config.options.bar.dynamicIsland.modules.message
                    onCheckedChanged: {
                        Config.options.bar.dynamicIsland.modules.message = checked;
                    }
                }

                ConfigSwitch {
                    buttonIcon: "today"
                    text: Translation.tr("Summary")
                    checked: Config.options.bar.dynamicIsland.modules.summary
                    onCheckedChanged: {
                        Config.options.bar.dynamicIsland.modules.summary = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "notifications"
                    text: Translation.tr("Notification")
                    checked: Config.options.bar.dynamicIsland.modules.notification
                    onCheckedChanged: {
                        Config.options.bar.dynamicIsland.modules.notification = checked;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
