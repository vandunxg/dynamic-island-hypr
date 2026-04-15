import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick.Controls
import qs.services

Item {
    id: controlCenter

    signal actionTriggered(actionName: string)
    signal volumeChanged(value: real)
    signal brightnessChanged(value: real)
    signal removeFileRequested(fileUrl: string)
    signal clearFilesRequested()
    signal convertTargetRequested(targetFormat: string)

    UserConfig {
        id: userConfig
    }

    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property string currentTime: "00:00"
    property string currentDateLabel: ""

    property string weatherTemp: "--"
    property string weatherCity: "Unknown"
    property string weatherCondition: "Weather"
    property string weatherWind: "--"

    property int batteryCapacity: 0
    property bool isCharging: false
    property real volumeLevel: -1
    property real brightnessLevel: -1
    property bool brightnessAvailable: brightnessLevel >= 0
    property int cpuUsagePercent: 0
    property int memoryUsagePercent: 0
    property string memoryUsageLabel: "--"
    property int swapUsagePercent: 0
    property int currentWorkspace: 1
    property string currentTrack: ""
    property string currentArtist: ""
    property var fileTrayEntries: []
    property bool fileDropActive: false
    property bool fileDropHovering: false
    property bool fileConvertPickerActive: false
    property bool fileConvertActive: false
    property bool fileConvertDone: false
    property bool fileConvertFailed: false
    property int fileConvertCount: 0
    property string fileConvertTargetFormat: ""
    property bool immediateHide: false
    property bool fileTrayDragActive: false
    property string fileDropTarget: "tray"
    property string quickDetailPanel: ""
    property string quickFocusMode: Notifications.silent ? "dnd" : "off"
    property string quickPowerProfile: "unknown"
    property string quickVpnStatus: "unknown"
    property bool quickVolumeDragging: false
    property bool quickBrightnessDragging: false
    property real quickVolumeUi: Math.max(0, volumeLevel)
    property real quickBrightnessUi: Math.max(0, brightnessLevel)
    property bool quickWifiPending: false
    property bool quickWifiTarget: false
    property bool quickBluetoothPending: false
    property bool quickBluetoothTarget: false
    property bool quickNightLightPending: false
    property bool quickNightLightTarget: false

    property int pageIndex: 0
    property real dragOffset: 0

    readonly property bool hasFileTray: fileDropActive
        || fileConvertPickerActive
        || fileConvertActive
        || fileConvertDone
        || fileConvertFailed
        || (fileTrayEntries && fileTrayEntries.length > 0)
    readonly property bool dragChoiceMode: fileDropActive
    readonly property bool convertPickerMode: fileConvertPickerActive && !fileDropActive
    readonly property bool convertCompactMode: (fileConvertActive || fileConvertDone || fileConvertFailed) && !fileDropActive
    readonly property bool compactMode: dragChoiceMode || convertPickerMode || convertCompactMode
    readonly property int pageCount: compactMode ? 1 : (hasFileTray ? 4 : 3)
    readonly property int fileTrayPageIndex: 0
    readonly property int weatherPageIndex: hasFileTray ? 1 : 0
    readonly property int systemPageIndex: hasFileTray ? 2 : 1
    readonly property int quickControlsPageIndex: hasFileTray ? 3 : 2
    readonly property real defaultCapsuleWidth: 352
    readonly property real quickCapsuleWidth: 352
    readonly property real defaultCapsuleHeight: 176
    readonly property real quickCapsuleHeight: quickDetailPanel !== "" ? 324 : 300
    readonly property real preferredCapsuleWidth: !compactMode && pageIndex === quickControlsPageIndex
        ? quickCapsuleWidth
        : defaultCapsuleWidth
    readonly property real preferredCapsuleHeight: !compactMode && pageIndex === quickControlsPageIndex
        ? quickCapsuleHeight
        : defaultCapsuleHeight
    readonly property real revealProgress: showCondition ? 1 : 0
    readonly property real swipeThreshold: 34
    readonly property real pageStride: compactMode
        ? 88
        : defaultCapsuleHeight
    readonly property real standardViewportWidth: Math.max(272, defaultCapsuleWidth - 40)
    readonly property real standardViewportHeight: Math.max(136, defaultCapsuleHeight - 24)
    readonly property bool quickDetailOpen: quickDetailPanel !== ""
    readonly property int quickAnimTapMs: 88
    readonly property int quickAnimStateMs: 108
    readonly property string primaryTime: {
        const parts = String(currentTime || "").trim().split(/\s+/);
        return parts.length > 0 ? parts[0] : "00:00";
    }
    readonly property string timeSuffix: {
        const parts = String(currentTime || "").trim().split(/\s+/);
        return parts.length > 1 ? parts.slice(1).join(" ") : "";
    }
    readonly property string batteryStatusLabel: isCharging ? "Charging" : "Discharging"
    readonly property real cpuLoadRatio: Math.max(0, Math.min(1, cpuUsagePercent / 100.0))
    readonly property real estimatedCpuTempC: Math.max(36, Math.min(95, 38 + cpuUsagePercent * 0.38 + swapUsagePercent * 0.08))
    readonly property real cpuTempRatio: Math.max(0, Math.min(1, estimatedCpuTempC / 100.0))
    readonly property real memoryRatio: Math.max(0, Math.min(1, memoryUsagePercent / 100.0))
    readonly property real systemBatteryRatio: {
        if (quickHasBatteryCapability && Number.isFinite(Number(Battery.percentage)))
            return Math.max(0, Math.min(1, Number(Battery.percentage)));
        return Math.max(0, Math.min(1, Number(batteryCapacity) / 100));
    }
    readonly property int systemBatteryPercent: Math.round(systemBatteryRatio * 100)
    readonly property bool systemBatteryLow: quickHasBatteryCapability && systemBatteryPercent < 20
    readonly property string systemBatteryStatus: {
        if (!quickHasBatteryCapability)
            return "No battery";
        if (isCharging)
            return "Charging";
        return systemBatteryLow ? "Low (<20%)" : "Normal (>20%)";
    }
    readonly property string memoryPercentText: Number(memoryUsagePercent).toFixed(1) + "%"
    readonly property string cpuLoadStatus: cpuUsagePercent >= 85 ? "High" : (cpuUsagePercent >= 60 ? "Moderate" : "Good")
    readonly property string cpuTempStatus: estimatedCpuTempC >= 78 ? "Hot" : (estimatedCpuTempC >= 64 ? "Warm" : "Good")
    readonly property string convertFormatLabel: fileConvertTargetFormat !== ""
        ? fileConvertTargetFormat.toUpperCase()
        : "..."
    readonly property string convertBusyText: fileConvertCount > 1
        ? ("Converting " + fileConvertCount + " files to " + convertFormatLabel + "...")
        : ("Converting to " + convertFormatLabel + "...")
    readonly property string convertDoneText: fileConvertCount > 1
        ? (fileConvertCount + " files converted")
        : "File converted"
    readonly property string convertFailedText: fileConvertCount > 1
        ? ("Failed to convert " + fileConvertCount + " files")
        : "Convert failed"
    readonly property var convertTargetOptions: ["png", "jpg", "pdf", "webp", "zip"]
    readonly property string normalizedWeatherCondition: String(weatherCondition || "").toLowerCase()
    readonly property bool weatherIsRainy: /(rain|drizzle|shower|storm|thunder)/.test(normalizedWeatherCondition)
    readonly property bool weatherIsSnowy: /(snow|sleet|blizzard|ice|hail|flurr)/.test(normalizedWeatherCondition)
    readonly property bool weatherIsCloudy: /(cloud|overcast|mist|fog|haze|smoke)/.test(normalizedWeatherCondition)
    readonly property bool weatherIsSunny: !weatherIsRainy && !weatherIsSnowy && !weatherIsCloudy
    readonly property string weatherIconName: weatherIsRainy
        ? "weather-showers-scattered"
        : (weatherIsSnowy ? "weather-snow" : (weatherIsCloudy ? "weather-overcast" : "weather-clear"))
    readonly property bool weatherPageActive: !compactMode && pageIndex === weatherPageIndex
    readonly property bool quickWifiUiEnabled: quickWifiPending ? quickWifiTarget : Network.wifiEnabled
    readonly property bool quickBluetoothUiEnabled: quickBluetoothPending ? quickBluetoothTarget : BluetoothStatus.enabled
    readonly property bool quickNightLightUiActive: quickNightLightPending ? quickNightLightTarget : Hyprsunset.active
    readonly property bool quickCanToggleWifi: Network.wifiStatus !== "disabled"
        || quickWifiUiEnabled
        || (Network.friendlyWifiNetworks && Network.friendlyWifiNetworks.length > 0)
    readonly property bool quickHasWifiCapability: Network.ethernet || quickCanToggleWifi
    readonly property bool quickHasBluetoothCapability: BluetoothStatus.available
    readonly property bool quickHasBatteryCapability: Battery.available
    readonly property bool quickHasPowerProfileCapability: quickPowerProfile !== "unknown"
    readonly property bool quickHasPowerCapability: quickHasBatteryCapability || quickHasPowerProfileCapability
    readonly property bool quickHasBrightnessCapability: brightnessAvailable
    readonly property bool quickHasVolumeCapability: volumeLevel >= 0
    readonly property bool quickNetworkOnline: Network.ethernet || (quickWifiUiEnabled && Network.active !== null)
    readonly property int quickNetworkSignalStrength: Math.max(0, Math.min(100, Number(Network.networkStrength) || 0))
    readonly property string quickNetworkSubtitle: {
        if (!quickHasWifiCapability)
            return "Unavailable";
        if (Network.ethernet)
            return "Connected";
        if (!quickWifiUiEnabled)
            return "Off";
        if (Network.wifiConnecting || Network.wifiStatus === "connecting")
            return "Connecting";
        if (Network.active && Network.active.ssid)
            return String(Network.active.ssid);
        if (Network.networkName !== "")
            return String(Network.networkName);
        if (Network.wifiStatus === "limited")
            return "Limited";
        return "Disconnected";
    }
    readonly property string quickNetworkConnectivity: {
        if (!quickHasWifiCapability)
            return "Unavailable";
        if (Network.ethernet)
            return "Internet";
        if (!quickWifiUiEnabled)
            return "Off";
        if (Network.wifiConnecting || Network.wifiStatus === "connecting")
            return "Connecting";
        if (Network.wifiStatus === "limited")
            return "No internet";
        if (Network.wifiStatus === "connected")
            return "Online";
        return "Disconnected";
    }
    readonly property string quickBluetoothSubtitle: {
        if (!quickHasBluetoothCapability)
            return "Unavailable";
        if (!quickBluetoothUiEnabled)
            return "Off";
        if (BluetoothStatus.activeDeviceCount > 0)
            return BluetoothStatus.activeDeviceCount + " connected";
        return "On";
    }
    readonly property string quickFocusSubtitle: quickFocusModeLabel(quickFocusMode)
    readonly property string quickPowerSubtitle: {
        if (!quickHasPowerCapability)
            return "Unavailable";

        const profile = quickHasPowerProfileCapability
            ? quickPowerProfilePretty(quickPowerProfile)
            : "No profile";

        if (quickHasBatteryCapability) {
            const batteryPercent = Math.round((Battery.percentage || 0) * 100) + "%";
            if (Battery.isCharging)
                return batteryPercent + " · Charging";
            return quickHasPowerProfileCapability ? (batteryPercent + " · " + profile) : batteryPercent;
        }

        return profile;
    }
    readonly property string quickAudioOutputLabel: Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : "No audio output"
    readonly property string quickContextFooter: {
        const parts = [];
        if (quickVpnStatus === "connected")
            parts.push("VPN connected");
        if (quickHasBatteryCapability)
            parts.push(Math.round((Battery.percentage || 0) * 100) + "%");
        if (Audio.source && Audio.source.audio && Audio.source.audio.muted)
            parts.push("Mic muted");
        if (parts.length === 0)
            return "";
        return parts.join(" · ");
    }

    function clampPageIndex(value) {
        return Math.max(0, Math.min(pageCount - 1, value));
    }

    function setPage(index) {
        pageIndex = clampPageIndex(index);
    }

    function nextPage() {
        setPage(pageIndex + 1);
    }

    function previousPage() {
        setPage(pageIndex - 1);
    }

    function entryUrl(entry) {
        return String(entry && entry.url ? entry.url : "");
    }

    function entryName(entry) {
        return String(entry && entry.name ? entry.name : "file");
    }

    function entryPath(entry) {
        return String(entry && entry.path ? entry.path : "");
    }

    function entryIsImage(entry) {
        return !!(entry && entry.isImage);
    }

    function entryExtension(entry) {
        const lowerName = entryName(entry).toLowerCase();
        const match = /\.([a-z0-9]{1,10})$/.exec(lowerName);
        return match ? match[1] : "";
    }

    function entryLooksLikeFolder(entry) {
        const path = entryPath(entry);
        const url = entryUrl(entry);
        return path.endsWith("/") || url.endsWith("/");
    }

    function iconNameForEntry(entry) {
        if (entryLooksLikeFolder(entry))
            return "inode-directory";

        if (entryIsImage(entry))
            return "image-x-generic";

        const ext = entryExtension(entry);

        if (ext === "pdf")
            return "application-pdf";

        if (["doc", "docx", "odt", "rtf", "pages"].includes(ext))
            return "x-office-document";

        if (["xls", "xlsx", "ods", "csv", "numbers"].includes(ext))
            return "x-office-spreadsheet";

        if (["ppt", "pptx", "odp", "key"].includes(ext))
            return "x-office-presentation";

        if (["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "zst", "deb", "rpm"].includes(ext))
            return "package-x-generic";

        if (["mp3", "flac", "wav", "ogg", "opus", "m4a", "aac"].includes(ext))
            return "audio-x-generic";

        if (["mp4", "mkv", "webm", "mov", "avi", "wmv", "m4v", "flv"].includes(ext))
            return "video-x-generic";

        if (["ttf", "otf", "woff", "woff2"].includes(ext))
            return "font-x-generic";

        if (["appimage", "desktop", "exe", "msi", "run", "bin"].includes(ext))
            return "application-x-executable";

        if (["txt", "md", "log", "json", "xml", "yaml", "yml", "toml", "ini", "conf", "cfg", "nfo"].includes(ext))
            return "text-plain";

        if (["js", "jsx", "ts", "tsx", "py", "sh", "bash", "zsh", "fish", "c", "h", "cpp", "hpp", "rs", "go", "java", "kt", "lua", "php", "rb", "swift"].includes(ext))
            return "text-x-script";

        return "text-x-generic";
    }

    function iconSourceForEntry(entry) {
        const iconName = iconNameForEntry(entry);
        if (iconName !== "text-x-generic")
            return Quickshell.iconPath(iconName, "text-x-generic");

        const path = entryPath(entry);
        const lookup = path !== "" ? path : entryName(entry);
        return Quickshell.iconPath(lookup, "text-x-generic");
    }

    function quickOpenDetail(name) {
        quickDetailPanel = String(name || "");
        if (quickDetailFlick)
            quickDetailFlick.contentY = 0;
    }

    function quickCloseDetail() {
        quickDetailPanel = "";
        if (quickDetailFlick)
            quickDetailFlick.contentY = 0;
    }

    function quickSetFocusMode(mode) {
        const next = String(mode || "off").toLowerCase();
        quickFocusMode = next;
        Notifications.silent = next !== "off";
    }

    function quickFocusModeLabel(mode) {
        const key = String(mode || "off").toLowerCase();
        if (key === "dnd")
            return "Do Not Disturb";
        if (key === "work")
            return "Work";
        if (key === "meeting")
            return "Meeting";
        if (key === "gaming")
            return "Gaming";
        return "Off";
    }

    function quickFocusModeIcon(mode) {
        const key = String(mode || "off").toLowerCase();
        if (key === "dnd")
            return "moon";
        if (key === "work")
            return "briefcase";
        if (key === "meeting")
            return "calendar";
        if (key === "gaming")
            return "gamepad-2";
        return "bell-off";
    }

    function quickToggleNetwork() {
        if (!quickCanToggleWifi)
            return;

        quickWifiTarget = !quickWifiUiEnabled;
        quickWifiPending = true;
        quickWifiPendingReset.restart();
        Network.toggleWifi();
        Network.update();
    }

    function quickToggleBluetooth() {
        if (!Bluetooth.defaultAdapter)
            return;

        const nextEnabled = !quickBluetoothUiEnabled;
        quickBluetoothTarget = nextEnabled;
        quickBluetoothPending = true;
        quickBluetoothPendingReset.restart();
        Bluetooth.defaultAdapter.enabled = nextEnabled;
        if (!nextEnabled)
            Bluetooth.defaultAdapter.discovering = false;
    }

    function quickToggleNightLight() {
        quickNightLightTarget = !quickNightLightUiActive;
        quickNightLightPending = true;
        quickNightLightPendingReset.restart();
        Hyprsunset.toggle();
    }

    function quickSetVolume(value) {
        const clamped = Math.max(0, Math.min(1, Number(value) || 0));
        quickVolumeUi = clamped;
        volumeChanged(clamped);
    }

    function quickSetBrightness(value) {
        if (!quickHasBrightnessCapability)
            return;
        const clamped = Math.max(0, Math.min(1, Number(value) || 0));
        quickBrightnessUi = clamped;
        brightnessChanged(clamped);
    }

    function quickPowerProfilePretty(profile) {
        const key = String(profile || "").trim().toLowerCase();
        if (key === "performance")
            return "Performance";
        if (key === "power-saver")
            return "Power Saver";
        if (key === "balanced")
            return "Balanced";
        return "Unknown";
    }

    function quickPowerProfileIcon(profile) {
        const key = String(profile || "").trim().toLowerCase();
        if (key === "power-saver")
            return "battery";
        if (key === "performance")
            return "cpu";
        return "layout-grid";
    }

    function quickPowerProfileDescription(profile) {
        const key = String(profile || "").trim().toLowerCase();
        if (key === "power-saver")
            return "Lower power usage";
        if (key === "performance")
            return "Higher speed, more power draw";
        if (key === "balanced")
            return "Balanced power and performance";
        return "Profile unavailable";
    }

    function quickCyclePowerProfile() {
        if (!quickHasPowerProfileCapability)
            return;

        const order = ["power-saver", "balanced", "performance"];
        const current = String(quickPowerProfile || "balanced").toLowerCase();
        const currentIndex = order.indexOf(current);
        const next = order[(currentIndex + 1 + order.length) % order.length];
        quickSetPowerProfile(next);
    }

    function quickSetPowerProfile(profile) {
        if (!quickHasPowerProfileCapability)
            return;

        const next = String(profile || "").trim().toLowerCase();
        if (!["power-saver", "balanced", "performance"].includes(next))
            return;

        quickPowerProfile = next;
        powerProfileSet.command = ["sh", "-lc", "powerprofilesctl set '" + next + "' >/dev/null 2>&1 || true"];
        powerProfileSet.running = true;
    }

    function quickRefreshStatus() {
        if (!showCondition || compactMode)
            return;

        powerProfileGet.running = true;
        vpnStatusGet.running = true;
    }

    onVolumeLevelChanged: {
        if (!quickVolumeDragging)
            quickVolumeUi = Math.max(0, Math.min(1, volumeLevel));
    }

    onBrightnessLevelChanged: {
        if (!quickBrightnessDragging)
            quickBrightnessUi = Math.max(0, Math.min(1, brightnessLevel));
    }

    onHasFileTrayChanged: {
        if (hasFileTray)
            pageIndex = 0;
        else
            pageIndex = Math.max(0, Math.min(pageIndex, pageCount - 1));
    }

    onDragChoiceModeChanged: {
        if (dragChoiceMode) {
            pageIndex = 0;
            dragOffset = 0;
        }
    }

    onFileConvertPickerActiveChanged: {
        if (fileConvertPickerActive) {
            pageIndex = 0;
            dragOffset = 0;
        }
    }

    onFileConvertActiveChanged: {
        if (fileConvertActive) {
            pageIndex = 0;
            dragOffset = 0;
        }
    }

    onFileConvertDoneChanged: {
        if (fileConvertDone) {
            pageIndex = 0;
            dragOffset = 0;
        }
    }

    onFileConvertFailedChanged: {
        if (fileConvertFailed) {
            pageIndex = 0;
            dragOffset = 0;
        }
    }

    onPageCountChanged: {
        pageIndex = clampPageIndex(pageIndex);
    }

    onPageIndexChanged: {
        if (pageIndex !== quickControlsPageIndex)
            quickCloseDetail();
        else
            quickRefreshStatus();
    }

    onShowConditionChanged: {
        if (showCondition) {
            pageIndex = 0;
            dragOffset = 0;
            quickRefreshStatus();
        } else {
            quickCloseDetail();
            quickWifiPending = false;
            quickBluetoothPending = false;
            quickNightLightPending = false;
        }
    }

    onCompactModeChanged: {
        if (compactMode)
            quickCloseDetail();
    }

    Connections {
        target: Notifications

        function onSilentChanged() {
            quickFocusMode = Notifications.silent ? "dnd" : "off";
        }
    }

    Connections {
        target: Network

        function onWifiEnabledChanged() {
            if (quickWifiPending && Network.wifiEnabled === quickWifiTarget)
                quickWifiPending = false;
        }
    }

    Connections {
        target: BluetoothStatus

        function onEnabledChanged() {
            if (quickBluetoothPending && BluetoothStatus.enabled === quickBluetoothTarget)
                quickBluetoothPending = false;
        }
    }

    Connections {
        target: Hyprsunset

        function onActiveChanged() {
            if (quickNightLightPending && Hyprsunset.active === quickNightLightTarget)
                quickNightLightPending = false;
        }
    }

    Timer {
        id: quickStatusPoller

        interval: 7000
        running: controlCenter.showCondition && !controlCenter.compactMode
        repeat: true
        onTriggered: controlCenter.quickRefreshStatus()
    }

    Timer {
        id: quickWifiPendingReset

        interval: 900
        repeat: false
        onTriggered: controlCenter.quickWifiPending = false
    }

    Timer {
        id: quickBluetoothPendingReset

        interval: 900
        repeat: false
        onTriggered: controlCenter.quickBluetoothPending = false
    }

    Timer {
        id: quickNightLightPendingReset

        interval: 900
        repeat: false
        onTriggered: controlCenter.quickNightLightPending = false
    }

    Process {
        id: powerProfileGet

        command: ["sh", "-lc", "powerprofilesctl get 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim().toLowerCase();
                const validProfiles = ["power-saver", "balanced", "performance"];
                controlCenter.quickPowerProfile = validProfiles.includes(value) ? value : "unknown";
            }
        }
    }

    Process {
        id: powerProfileSet

        stdout: StdioCollector {
            onStreamFinished: {
                powerProfileGet.running = true;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                powerProfileGet.running = true;
            }
        }
    }

    Process {
        id: vpnStatusGet

        command: ["sh", "-lc", "nmcli -t -f TYPE,STATE connection show --active 2>/dev/null | awk -F: '$1 ~ /vpn/ && $2 ~ /activated/ { found=1 } END { print found ? \"connected\" : \"disconnected\" }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = String(text || "").trim().toLowerCase();
                controlCenter.quickVpnStatus = value !== "" ? value : "unknown";
            }
        }
    }

    anchors.fill: parent
    anchors.margins: compactMode ? 8 : 10
    opacity: revealProgress
    visible: opacity > 0
    scale: 0.987 + revealProgress * 0.013

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 280 : (immediateHide ? 0 : 160)
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: showCondition ? 300 : 170
            easing.type: Easing.InOutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: controlCenter.compactMode ? 24 : 28
        color: controlCenter.compactMode ? "#04070c" : "#050506"
    }

    Item {
        id: viewport

        anchors.fill: parent
        anchors.leftMargin: controlCenter.compactMode ? 10 : 14
        anchors.rightMargin: controlCenter.compactMode ? 10 : (controlCenter.pageIndex === controlCenter.quickControlsPageIndex ? 14 : 26)
        anchors.topMargin: controlCenter.compactMode ? 8 : 12
        anchors.bottomMargin: controlCenter.compactMode ? 8 : 12
        clip: true

        Item {
            id: pagesTrack

            width: parent.width
            height: controlCenter.pageStride * Math.max(0, controlCenter.pageCount - 1) + viewport.height
            y: -controlCenter.pageIndex * controlCenter.pageStride + controlCenter.dragOffset

            Behavior on y {
                enabled: !pageSwipeHandler.active

                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: fileTrayPage

                visible: controlCenter.hasFileTray
                y: controlCenter.pageStride * controlCenter.fileTrayPageIndex
                width: viewport.width
                height: viewport.height

                Item {
                    id: dragChoiceLayout

                    anchors.fill: parent
                    visible: controlCenter.dragChoiceMode
                    opacity: controlCenter.fileDropHovering ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "#050911"
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 7

                        Rectangle {
                            id: dragTrayChoice

                            width: Math.floor((parent.width - parent.spacing) / 2)
                            height: parent.height
                            radius: 16
                            color: controlCenter.fileDropTarget === "tray" ? "#0e2a45" : "#07111d"
                            border.width: 0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            Canvas {
                                id: trayChoiceDash

                                anchors.fill: parent
                                antialiasing: true

                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                Connections {
                                    target: controlCenter

                                    function onFileDropTargetChanged() {
                                        trayChoiceDash.requestPaint();
                                    }
                                }

                                onPaint: {
                                    const ctx = getContext("2d");
                                    const w = width;
                                    const h = height;
                                    const r = 16;
                                    const dash = 9;
                                    const gap = 5;

                                    ctx.clearRect(0, 0, w, h);
                                    ctx.setLineDash([dash, gap]);
                                    ctx.lineWidth = 2;
                                    ctx.strokeStyle = controlCenter.fileDropTarget === "tray" ? "#4eb7ff" : "#2e4f6a";
                                    ctx.beginPath();
                                    ctx.moveTo(r, 1);
                                    ctx.arcTo(w - 1, 1, w - 1, h - 1, r);
                                    ctx.arcTo(w - 1, h - 1, 1, h - 1, r);
                                    ctx.arcTo(1, h - 1, 1, 1, r);
                                    ctx.arcTo(1, 1, w - 1, 1, r);
                                    ctx.closePath();
                                    ctx.stroke();
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 9

                                LucideIcon {
                                    width: 16
                                    height: 16
                                    iconName: "layout-grid"
                                    opacity: 0.98
                                }

                                Text {
                                    text: "Files Tray"
                                    color: "#49b9ff"
                                    font.pixelSize: 11
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Rectangle {
                            id: dragConvertChoice

                            width: parent.width - dragTrayChoice.width - parent.spacing
                            height: parent.height
                            radius: 16
                            color: "transparent"
                            border.width: controlCenter.fileDropTarget === "convert" ? 1 : 0
                            border.color: controlCenter.fileDropTarget === "convert" ? "#6eb7ff" : "#2c527f"

                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: controlCenter.fileDropTarget === "convert" ? "#123968" : "#0d2a4a"
                                }
                                GradientStop {
                                    position: 1
                                    color: controlCenter.fileDropTarget === "convert" ? "#1a5eaf" : "#113f78"
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 120
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 9

                                LucideIcon {
                                    width: 16
                                    height: 16
                                    iconName: "refresh-cw"
                                    opacity: 0.95
                                }

                                Text {
                                    text: "Convert File"
                                    color: "#e0ecff"
                                    font.pixelSize: 11
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                Item {
                    id: convertPickerLayout

                    anchors.fill: parent
                    visible: controlCenter.convertPickerMode

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "#050911"
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 7
                        radius: 16
                        border.width: 1
                        border.color: "#5ea9f5"
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#10355f"
                            }
                            GradientStop {
                                position: 1
                                color: "#184f8d"
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 5

                            Text {
                                text: "Convert to"
                                color: "#e7f1ff"
                                font.pixelSize: 10
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }

                            Row {
                                id: convertTargetRow

                                width: parent.width
                                height: 30
                                spacing: 5

                                Repeater {
                                    model: controlCenter.convertTargetOptions

                                    delegate: Rectangle {
                                        required property var modelData

                                        width: (convertTargetRow.width - convertTargetRow.spacing * (controlCenter.convertTargetOptions.length - 1)) / controlCenter.convertTargetOptions.length
                                        height: parent.height
                                        radius: 10
                                        color: pickerTargetMouse.pressed
                                            ? "#2a6fb0"
                                            : (pickerTargetMouse.containsMouse ? "#225f98" : "#163f67")
                                        border.width: 1
                                        border.color: pickerTargetMouse.containsMouse ? "#9dcdfc" : "#4f84b8"

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(modelData).toUpperCase()
                                            color: "#eff6ff"
                                            font.pixelSize: 9
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            id: pickerTargetMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: controlCenter.convertTargetRequested(String(modelData))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: convertBusyLayout

                    anchors.fill: parent
                    visible: controlCenter.convertCompactMode

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "#050911"
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 7
                        radius: 16
                        border.width: 1
                        border.color: controlCenter.fileConvertDone
                            ? "#89d9a0"
                            : (controlCenter.fileConvertFailed ? "#f09ba6" : "#5ea9f5")
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: controlCenter.fileConvertDone
                                    ? "#1c5031"
                                    : (controlCenter.fileConvertFailed ? "#5a2430" : "#10355f")
                            }
                            GradientStop {
                                position: 1
                                color: controlCenter.fileConvertDone
                                    ? "#286a41"
                                    : (controlCenter.fileConvertFailed ? "#7a3040" : "#184f8d")
                            }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            LucideIcon {
                                id: convertBusyIcon

                                width: 17
                                height: 17
                                iconName: "refresh-cw"
                                opacity: 0.96

                                RotationAnimator on rotation {
                                    from: 0
                                    to: 360
                                    duration: 900
                                    loops: Animation.Infinite
                                    running: convertBusyLayout.visible && !controlCenter.fileConvertDone && !controlCenter.fileConvertFailed
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: controlCenter.fileConvertDone || controlCenter.fileConvertFailed
                                    text: controlCenter.fileConvertDone ? "OK" : "NO"
                                    color: controlCenter.fileConvertDone ? "#dcffe8" : "#ffd9df"
                                    font.pixelSize: 8
                                    font.family: heroFontFamily
                                    font.weight: Font.Bold
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: controlCenter.fileConvertDone
                                        ? "Convert Done"
                                        : (controlCenter.fileConvertFailed ? "Convert Failed" : "Convert File")
                                    color: "#e8f2ff"
                                    font.pixelSize: 11
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: controlCenter.fileConvertDone
                                        ? controlCenter.convertDoneText
                                        : (controlCenter.fileConvertFailed ? controlCenter.convertFailedText : controlCenter.convertBusyText)
                                    color: "#c4d9f3"
                                    font.pixelSize: 9
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Column {
                    id: trayContentLayout

                    anchors.fill: parent
                    visible: !controlCenter.compactMode
                    spacing: 6

                    Item {
                        id: trayHeader

                        width: parent.width
                        height: 24

                        Text {
                            id: trayTitle

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Files Tray"
                            color: "#f0f3f8"
                            font.pixelSize: 11
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.left: trayTitle.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(controlCenter.fileTrayEntries.length) + " files"
                            color: "#97a2b2"
                            font.pixelSize: 9
                            font.family: textFontFamily
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            id: clearAllButton

                            readonly property bool enabledState: (controlCenter.fileTrayEntries && controlCenter.fileTrayEntries.length > 0) && !controlCenter.fileDropActive

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 78
                            height: 22
                            radius: 11
                            color: clearAllMouse.pressed
                                ? "#1c2734"
                                : (clearAllMouse.containsMouse ? "#182330" : "#101820")
                            border.width: 1
                            border.color: enabledState ? "#31465c" : "#243241"
                            opacity: enabledState ? 1 : 0.45

                            Text {
                                anchors.centerIn: parent
                                text: "Clear files"
                                color: "#d6e0ec"
                                font.pixelSize: 9
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            MouseArea {
                                id: clearAllMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: clearAllButton.enabledState
                                onClicked: controlCenter.clearFilesRequested()
                            }
                        }
                    }

                    Rectangle {
                        id: trayShell

                        width: parent.width
                        height: parent.height - trayHeader.height - parent.spacing
                        radius: 14
                        color: "#080b10"
                        border.width: 1
                        border.color: "#1a2230"
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: parent.radius - 1
                            color: "transparent"
                            border.width: 1
                            border.color: "#0d121b"
                        }

                        ListView {
                            id: trayList

                            anchors.fill: parent
                            anchors.margins: 8
                            orientation: ListView.Horizontal
                            spacing: 10
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: !controlCenter.fileTrayDragActive && contentWidth > width
                            snapMode: ListView.SnapOneItem
                            flickDeceleration: 8600
                            maximumFlickVelocity: 3200
                            cacheBuffer: 500
                            model: ScriptModel {
                                values: controlCenter.fileTrayEntries || []
                            }

                            delegate: Item {
                                id: fileChip

                                required property var modelData

                                readonly property var entry: modelData
                                property bool draggingOut: false
                                property bool removedAfterDrag: false
                                property bool exitedTrayBounds: false
                                property real dragDistance: 0

                                property string fileUrl: controlCenter.entryUrl(entry)
                                property bool imageEntry: controlCenter.entryIsImage(entry)
                                property string iconSource: controlCenter.iconSourceForEntry(entry)
                                property string dragPreviewSource: imageEntry ? fileUrl : iconSource
                                property bool hovered: chipHover.hovered
                                property bool pressed: chipDragHandler.active
                                readonly property real centerDistance: Math.abs((x + width / 2) - (trayList.contentX + trayList.width / 2))
                                readonly property real focusFactor: Math.max(0, 1 - centerDistance / Math.max(trayList.width * 0.52, 1))

                                function pointerInsideTrayNow() {
                                    const px = chipDragHandler.centroid.position.x;
                                    const py = chipDragHandler.centroid.position.y;
                                    const mapped = fileChip.mapToItem(
                                        trayShell,
                                        px === undefined ? fileChip.width / 2 : px,
                                        py === undefined ? fileChip.height / 2 : py
                                    );

                                    return mapped.x >= 0
                                        && mapped.x <= trayShell.width
                                        && mapped.y >= 0
                                        && mapped.y <= trayShell.height;
                                }

                                width: 82
                                height: trayList.height
                                z: chipDragHandler.active ? 1000 : 0
                                Drag.active: chipDragHandler.active
                                Drag.dragType: Drag.Automatic
                                Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                                Drag.mimeData: ({
                                        "text/uri-list": fileUrl,
                                        "text/plain": fileUrl
                                    })
                                Drag.imageSource: dragPreviewSource
                                Drag.imageSourceSize: Qt.size(86, 54)
                                Drag.hotSpot.x: 40
                                Drag.hotSpot.y: 22
                                scale: pressed ? 1.04 : (0.9 + focusFactor * 0.1)
                                opacity: pressed ? 1 : (0.56 + focusFactor * 0.44)
                                y: pressed ? 1 : (1 - focusFactor) * 5

                                Drag.onDragFinished: dropAction => {
                                    fileChip.draggingOut = false;
                                    controlCenter.fileTrayDragActive = false;
                                    const endedInsideTray = fileChip.pointerInsideTrayNow();
                                    const shouldRemove = dropAction !== Qt.IgnoreAction
                                        || fileChip.exitedTrayBounds
                                        || !endedInsideTray
                                        || (fileChip.dragDistance > 12 && !chipHover.hovered);

                                    if (!fileChip.removedAfterDrag && shouldRemove) {
                                        fileChip.removedAfterDrag = true;
                                        controlCenter.removeFileRequested(fileUrl);
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on y {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: hovered ? "#0f1824" : "#090f16"
                                    border.width: pressed ? 1.6 : (hovered ? 1.3 : 1)
                                    border.color: pressed ? "#76beff" : (hovered ? "#4d9be8" : "#223040")
                                }

                                Rectangle {
                                    id: previewWrap

                                    anchors.top: parent.top
                                    anchors.topMargin: 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 62
                                    height: 30
                                    radius: 7
                                    color: "#0f1722"
                                    border.width: 1
                                    border.color: "#2a3b4e"
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: fileChip.imageEntry ? fileChip.fileUrl : fileChip.iconSource
                                        fillMode: fileChip.imageEntry ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                        sourceSize: Qt.size(96, 64)
                                        asynchronous: true
                                        smooth: true
                                        mipmap: true
                                    }
                                }

                                Rectangle {
                                    visible: pressed
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.right: previewWrap.right
                                    anchors.rightMargin: -5
                                    anchors.bottom: previewWrap.bottom
                                    anchors.bottomMargin: -5
                                    color: "#62ce65"
                                    border.width: 1
                                    border.color: "#2b8f2f"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.family: heroFontFamily
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: previewWrap.bottom
                                    anchors.topMargin: 5
                                    horizontalAlignment: Text.AlignHCenter
                                    text: controlCenter.entryName(entry)
                                    color: "#d9e0ea"
                                    font.pixelSize: 8
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                HoverHandler {
                                    id: chipHover
                                }

                                DragHandler {
                                    id: chipDragHandler

                                    target: null
                                    acceptedButtons: Qt.LeftButton
                                    grabPermissions: PointerHandler.CanTakeOverFromAnything | PointerHandler.ApprovesTakeOverByAnything

                                    onActiveChanged: {
                                        fileChip.draggingOut = active;
                                        controlCenter.fileTrayDragActive = active;

                                        if (active) {
                                            fileChip.removedAfterDrag = false;
                                            fileChip.exitedTrayBounds = false;
                                            fileChip.dragDistance = 0;
                                            return;
                                        }

                                        const endedInsideTray = fileChip.pointerInsideTrayNow();
                                        if (!fileChip.removedAfterDrag
                                                && fileChip.dragDistance > 12
                                                && (fileChip.exitedTrayBounds || !endedInsideTray || !chipHover.hovered)) {
                                            fileChip.removedAfterDrag = true;
                                            controlCenter.removeFileRequested(fileUrl);
                                        }
                                    }

                                    onTranslationChanged: {
                                        const tx = translation.x;
                                        const ty = translation.y;
                                        fileChip.dragDistance = Math.max(fileChip.dragDistance, Math.sqrt(tx * tx + ty * ty));

                                        const insideTray = fileChip.pointerInsideTrayNow();
                                        if (!insideTray)
                                            fileChip.exitedTrayBounds = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: weatherPage

                property real ambientMotion: 0
                property real ambientGlow: 0

                y: controlCenter.pageStride * controlCenter.weatherPageIndex + (controlCenter.weatherPageActive ? ((ambientMotion - 0.5) * 1.4) : 0)
                width: viewport.width
                height: viewport.height
                scale: controlCenter.weatherPageActive ? (0.998 + ambientGlow * 0.006) : 1
                transformOrigin: Item.Center

                SequentialAnimation on ambientMotion {
                    running: controlCenter.weatherPageActive
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 0
                        to: 1
                        duration: 2200
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: 1
                        to: 0
                        duration: 2200
                        easing.type: Easing.InOutSine
                    }
                }

                SequentialAnimation on ambientGlow {
                    running: controlCenter.weatherPageActive
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 0
                        to: 1
                        duration: 1900
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        from: 1
                        to: 0
                        duration: 1900
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Item {
                    id: weatherViewportFrame

                    width: Math.min(parent.width, controlCenter.standardViewportWidth)
                    height: Math.min(parent.height, controlCenter.standardViewportHeight)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    Row {
                        anchors.fill: parent
                        spacing: 10

                    Item {
                        id: weatherLeftColumn

                        width: 84
                        height: parent.height

                        Item {
                            id: weatherIconWrap

                            width: 30
                            height: 30
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top

                            property real sunnyPulse: 0
                            property real driftOffset: 0

                            SequentialAnimation on sunnyPulse {
                                running: controlCenter.weatherPageActive && controlCenter.weatherIsSunny
                                loops: Animation.Infinite

                                NumberAnimation {
                                    from: 0
                                    to: 1
                                    duration: 1850
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    from: 1
                                    to: 0
                                    duration: 1850
                                    easing.type: Easing.InOutSine
                                }
                            }

                            SequentialAnimation on driftOffset {
                                running: controlCenter.weatherPageActive && (controlCenter.weatherIsRainy || controlCenter.weatherIsCloudy || controlCenter.weatherIsSnowy)
                                loops: Animation.Infinite

                                NumberAnimation {
                                    from: -1.2
                                    to: 1.2
                                    duration: 1700
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    from: 1.2
                                    to: -1.2
                                    duration: 1700
                                    easing.type: Easing.InOutSine
                                }
                            }

                            Image {
                                id: weatherIconImage

                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                source: Quickshell.iconPath(controlCenter.weatherIconName, "weather-clear")
                                sourceSize: Qt.size(56, 56)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                rotation: controlCenter.weatherPageActive && controlCenter.weatherIsSunny ? weatherIconWrap.sunnyPulse * 7 : 0
                                scale: controlCenter.weatherPageActive && controlCenter.weatherIsSunny ? (1 + weatherIconWrap.sunnyPulse * 0.08) : 1
                                y: controlCenter.weatherPageActive ? weatherIconWrap.driftOffset : 0
                                opacity: 0.95

                                Behavior on y {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutSine
                                    }
                                }
                            }

                            Repeater {
                                model: 3

                                delegate: Rectangle {
                                    required property int index

                                    width: 2
                                    height: 6
                                    radius: 1
                                    x: 7 + index * 8
                                    y: 18
                                    color: "#8fd5ff"
                                    opacity: 0
                                    visible: controlCenter.weatherPageActive && controlCenter.weatherIsRainy

                                    SequentialAnimation on y {
                                        running: controlCenter.weatherPageActive && controlCenter.weatherIsRainy
                                        loops: Animation.Infinite

                                        PauseAnimation {
                                            duration: index * 130
                                        }

                                        NumberAnimation {
                                            from: 17
                                            to: 28
                                            duration: 430
                                            easing.type: Easing.InQuad
                                        }

                                        PauseAnimation {
                                            duration: 110
                                        }
                                    }

                                    SequentialAnimation on opacity {
                                        running: controlCenter.weatherPageActive && controlCenter.weatherIsRainy
                                        loops: Animation.Infinite

                                        PauseAnimation {
                                            duration: index * 130
                                        }

                                        NumberAnimation {
                                            from: 0
                                            to: 0.92
                                            duration: 130
                                            easing.type: Easing.OutQuad
                                        }

                                        NumberAnimation {
                                            from: 0.92
                                            to: 0
                                            duration: 300
                                            easing.type: Easing.InQuad
                                        }

                                        PauseAnimation {
                                            duration: 110
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 34
                            text: weatherTemp
                            color: "#f6f7f9"
                            font.pixelSize: 34
                            font.family: heroFontFamily
                            font.weight: Font.Bold
                            font.letterSpacing: -0.5
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignHCenter
                            text: "Ha Noi"
                            color: "#dee2ea"
                            font.pixelSize: 11
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: parent.width - weatherLeftColumn.width - parent.spacing
                        height: parent.height

                        Item {
                            id: timeBlock

                            width: parent.width
                            height: 70

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: "#0d1623"
                                border.width: 1
                                border.color: "#223548"
                                opacity: 0.18 + (controlCenter.weatherPageActive ? weatherPage.ambientGlow * 0.08 : 0)

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    id: primaryTimeLabel

                                    text: primaryTime
                                    color: "#f7f9fc"
                                    font.pixelSize: 52
                                    font.family: heroFontFamily
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.9
                                }

                                Text {
                                    text: timeSuffix
                                    visible: text !== ""
                                    color: "#f2f4f8"
                                    font.pixelSize: 16
                                    font.family: textFontFamily
                                    font.weight: Font.DemiBold
                                    anchors.baseline: primaryTimeLabel.baseline
                                    anchors.baselineOffset: -6
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: timeBlock.bottom
                            anchors.topMargin: 0
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: currentDateLabel
                            color: "#e8ebf0"
                            font.pixelSize: 12
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignHCenter
                            text: weatherCondition + " • " + weatherWind
                            color: "#aab0bc"
                            font.pixelSize: 10
                            font.family: textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            }

            Item {
                id: systemPage

                visible: controlCenter.pageIndex !== controlCenter.quickControlsPageIndex || pageSwipeHandler.active
                y: controlCenter.pageStride * controlCenter.systemPageIndex
                width: viewport.width
                height: viewport.height

                Item {
                    id: systemViewportFrame

                    width: Math.min(parent.width, controlCenter.standardViewportWidth)
                    height: Math.min(parent.height, controlCenter.standardViewportHeight)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    Column {
                        anchors.fill: parent
                        spacing: 6

                    Item {
                        width: parent.width
                        height: 22

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "System Overview"
                            color: "#f4f6fa"
                            font.pixelSize: 16
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }
                    }

                    Row {
                        id: performanceRow

                        width: parent.width
                        height: parent.height - 22 - parent.spacing
                        spacing: 6

                        Repeater {
                            model: 4

                            delegate: Item {
                                id: metricCard

                                required property int index

                                readonly property bool cpuCard: index === 0
                                readonly property bool tempCard: index === 1
                                readonly property bool memoryCard: index === 2
                                readonly property bool batteryCard: index === 3
                                readonly property color statusGoodColor: "#4fd18f"
                                readonly property color statusWarnColor: "#f2be57"
                                readonly property color statusDangerColor: "#ff6b6b"
                                readonly property color statusNeutralColor: "#95a3b7"
                                readonly property color ringColor: cpuCard
                                    ? (controlCenter.cpuUsagePercent >= 80
                                        ? statusDangerColor
                                        : (controlCenter.cpuUsagePercent >= 55 ? statusWarnColor : statusGoodColor))
                                    : (tempCard
                                        ? (controlCenter.estimatedCpuTempC >= 78
                                            ? statusDangerColor
                                            : (controlCenter.estimatedCpuTempC >= 64 ? statusWarnColor : statusGoodColor))
                                        : (memoryCard
                                            ? (controlCenter.memoryUsagePercent >= 85
                                                ? statusDangerColor
                                                : (controlCenter.memoryUsagePercent >= 65 ? statusWarnColor : statusGoodColor))
                                            : (!controlCenter.quickHasBatteryCapability
                                                ? statusNeutralColor
                                                : (controlCenter.systemBatteryPercent <= 20
                                                    ? statusDangerColor
                                                    : (controlCenter.systemBatteryPercent <= 35 ? statusWarnColor : statusGoodColor)))))
                                readonly property color valueColor: batteryCard && !controlCenter.quickHasBatteryCapability
                                    ? statusNeutralColor
                                    : ringColor
                                readonly property real ringSize: Math.max(44, Math.min(50, performanceRow.height * 0.45))
                                readonly property real progressValue: cpuCard
                                    ? controlCenter.cpuLoadRatio
                                    : (tempCard
                                        ? controlCenter.cpuTempRatio
                                        : (memoryCard
                                            ? controlCenter.memoryRatio
                                            : controlCenter.systemBatteryRatio))
                                property real animatedProgress: progressValue
                                readonly property real percentageValue: animatedProgress * 100
                                readonly property string centerPercentText: batteryCard
                                    ? (controlCenter.quickHasBatteryCapability ? (Math.round(percentageValue) + "%") : "N/A")
                                    : (tempCard
                                        ? (Math.round(controlCenter.estimatedCpuTempC) + "°C")
                                        : (cpuCard ? (Math.round(percentageValue) + "%") : (Math.round(percentageValue) + "%")))
                                readonly property string titleText: cpuCard
                                    ? "CPU"
                                    : (tempCard ? "Temp" : (memoryCard ? "Memory" : "Battery"))
                                readonly property string footerText: cpuCard
                                    ? controlCenter.cpuLoadStatus
                                    : (tempCard
                                        ? controlCenter.cpuTempStatus
                                        : (memoryCard
                                            ? (Math.round(controlCenter.memoryUsagePercent) + "% used")
                                            : controlCenter.systemBatteryStatus))

                                width: (performanceRow.width - performanceRow.spacing * 3) / 4
                                height: performanceRow.height

                                onProgressValueChanged: {
                                    animatedProgress = progressValue;
                                }

                                Behavior on animatedProgress {
                                    NumberAnimation {
                                        duration: 380
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: "#090c12"
                                    border.width: 1
                                    border.color: "#16202a"
                                    opacity: 0.8
                                }

                                Column {
                                    width: parent.width - 8
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Item {
                                        width: parent.width
                                        height: metricCard.ringSize

                                        Item {
                                            id: ringWrap

                                            width: metricCard.ringSize
                                            height: metricCard.ringSize
                                            anchors.centerIn: parent

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                color: "transparent"
                                                border.width: 1
                                                border.color: "#2a3543"
                                            }

                                            Canvas {
                                                id: ringCanvas

                                                anchors.fill: parent
                                                antialiasing: true

                                                property real currentProgress: Math.max(0, Math.min(1, Number(metricCard.animatedProgress) || 0))
                                                property color activeColor: metricCard.ringColor

                                                onCurrentProgressChanged: requestPaint()
                                                onActiveColorChanged: requestPaint()
                                                onWidthChanged: requestPaint()
                                                onHeightChanged: requestPaint()

                                                onPaint: {
                                                    const ctx = getContext("2d");
                                                    const centerX = width / 2;
                                                    const centerY = height / 2;
                                                    const radius = Math.min(width, height) / 2 - 3.2;
                                                    const lineWidth = 4.1;
                                                    const startAngle = -Math.PI / 2;
                                                    const clampedProgress = Math.max(0, Math.min(1, currentProgress));
                                                    const endAngle = startAngle + Math.PI * 2 * clampedProgress;

                                                    ctx.clearRect(0, 0, width, height);
                                                    ctx.lineWidth = lineWidth;
                                                    ctx.lineCap = "round";

                                                    ctx.strokeStyle = Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.28);
                                                    ctx.beginPath();
                                                    ctx.arc(centerX, centerY, radius, startAngle, Math.PI * 1.5, false);
                                                    ctx.stroke();

                                                    if (clampedProgress > 0.001) {
                                                        ctx.strokeStyle = Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.98);
                                                        ctx.beginPath();
                                                        ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                                                        ctx.stroke();
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: parent.width - 14
                                                height: width
                                                radius: width / 2
                                                color: "#05070a"
                                                border.width: 1
                                                border.color: "#1f2834"
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                anchors.verticalCenterOffset: -1
                                                text: metricCard.centerPercentText
                                                color: metricCard.valueColor
                                                font.pixelSize: metricCard.tempCard ? 11 : (metricCard.batteryCard ? 10 : 12)
                                                font.family: heroFontFamily
                                                font.weight: Font.Bold
                                                font.letterSpacing: -0.2
                                            }
                                        }
                                    }

                                    Text {
                                        height: 12
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: titleText
                                        color: "#c9d4e3"
                                        font.pixelSize: 8
                                        font.family: textFontFamily
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        height: 12
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: footerText
                                        color: batteryCard
                                            ? (controlCenter.systemBatteryLow ? "#ff9898" : (controlCenter.isCharging ? "#9fcfff" : "#9cd5b2"))
                                            : "#b8c6d7"
                                        font.pixelSize: 7
                                        font.family: textFontFamily
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            }

            Item {
                id: quickControlsPage

                y: controlCenter.pageStride * controlCenter.quickControlsPageIndex
                width: viewport.width
                height: viewport.height

                readonly property bool panelActive: controlCenter.pageIndex === controlCenter.quickControlsPageIndex && !controlCenter.compactMode
                readonly property real tileHeight: 56
                readonly property real sliderHeight: 50
                readonly property real footerHeight: 22
                readonly property real moduleGap: 7
                readonly property real topSectionHeight: tileHeight * 2 + moduleGap

                Component.onCompleted: controlCenter.quickRefreshStatus()

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: "#06080d"
                    border.width: 0
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 7

                    Item {
                        width: parent.width
                        height: quickControlsPage.topSectionHeight

                        Grid {
                            anchors.fill: parent
                            columns: 2
                            rowSpacing: quickControlsPage.moduleGap
                            columnSpacing: quickControlsPage.moduleGap

                            Rectangle {
                                id: wifiTile

                                width: (parent.width - parent.columnSpacing) / 2
                                height: quickControlsPage.tileHeight
                                radius: 14
                                color: controlCenter.quickNetworkOnline ? "#1a2a43" : "#171d28"
                                border.width: 0
                                opacity: controlCenter.quickHasWifiCapability ? 1 : 0.55
                                scale: wifiTileTap.pressed ? 0.985 : 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: controlCenter.quickAnimStateMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: controlCenter.quickAnimTapMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    id: wifiTileTap

                                    anchors.fill: parent
                                    enabled: controlCenter.quickHasWifiCapability
                                    onClicked: controlCenter.quickOpenDetail("network")
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#2d4f80"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            iconName: controlCenter.quickWifiUiEnabled ? "wifi" : "wifi-off"
                                        }
                                    }

                                    Column {
                                        width: parent.width - 22 - 40 - parent.spacing * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            text: "Wi-Fi"
                                            color: "#e7eef9"
                                            font.pixelSize: 10
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: controlCenter.quickNetworkSubtitle
                                            color: "#9eb0c6"
                                            font.pixelSize: 8
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickCanToggleWifi && controlCenter.quickWifiUiEnabled ? "#3d81e0" : "#2a3548"
                                        border.width: 0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: controlCenter.quickCanToggleWifi && controlCenter.quickWifiUiEnabled ? (parent.width - width - 2) : 2
                                            color: "#edf5ff"

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: controlCenter.quickAnimStateMs
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: controlCenter.quickCanToggleWifi
                                            onClicked: {
                                                mouse.accepted = true;
                                                controlCenter.quickToggleNetwork();
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: bluetoothTile

                                width: (parent.width - parent.columnSpacing) / 2
                                height: quickControlsPage.tileHeight
                                radius: 14
                                color: (controlCenter.quickHasBluetoothCapability && controlCenter.quickBluetoothUiEnabled) ? "#1a2a43" : "#171d28"
                                border.width: 0
                                opacity: controlCenter.quickHasBluetoothCapability ? 1 : 0.55
                                scale: bluetoothTileTap.pressed ? 0.985 : 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: controlCenter.quickAnimStateMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: controlCenter.quickAnimTapMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    id: bluetoothTileTap

                                    anchors.fill: parent
                                    enabled: controlCenter.quickHasBluetoothCapability
                                    onClicked: controlCenter.quickOpenDetail("bluetooth")
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#2d4f80"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            iconName: "bluetooth"
                                        }
                                    }

                                    Column {
                                        width: parent.width - 22 - 40 - parent.spacing * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            text: "Bluetooth"
                                            color: "#e7eef9"
                                            font.pixelSize: 10
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: controlCenter.quickBluetoothSubtitle
                                            color: "#9eb0c6"
                                            font.pixelSize: 8
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickBluetoothUiEnabled ? "#3d81e0" : "#2a3548"
                                        border.width: 0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: controlCenter.quickBluetoothUiEnabled ? (parent.width - width - 2) : 2
                                            color: "#edf5ff"

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: controlCenter.quickAnimStateMs
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: controlCenter.quickHasBluetoothCapability
                                            onClicked: {
                                                mouse.accepted = true;
                                                controlCenter.quickToggleBluetooth();
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: focusTile

                                width: (parent.width - parent.columnSpacing) / 2
                                height: quickControlsPage.tileHeight
                                radius: 14
                                color: controlCenter.quickFocusMode !== "off" ? "#2a2340" : "#171d28"
                                border.width: 0
                                scale: focusTileTap.pressed ? 0.985 : 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: controlCenter.quickAnimStateMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: controlCenter.quickAnimTapMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    id: focusTileTap

                                    anchors.fill: parent
                                    onClicked: controlCenter.quickOpenDetail("focus")
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickFocusMode !== "off" ? "#5d478f" : "#2a3548"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            iconName: controlCenter.quickFocusModeIcon(controlCenter.quickFocusMode)
                                        }
                                    }

                                    Column {
                                        width: parent.width - 22 - 40 - parent.spacing * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            text: "Focus"
                                            color: "#e7eef9"
                                            font.pixelSize: 10
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: controlCenter.quickFocusSubtitle
                                            color: "#9eb0c6"
                                            font.pixelSize: 8
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickFocusMode !== "off" ? "#6b4fa6" : "#2a3548"
                                        border.width: 0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: controlCenter.quickFocusMode !== "off" ? (parent.width - width - 2) : 2
                                            color: controlCenter.quickFocusMode !== "off" ? "#f4eaff" : "#edf5ff"

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: controlCenter.quickAnimStateMs
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                mouse.accepted = true;
                                                controlCenter.quickSetFocusMode(controlCenter.quickFocusMode === "off" ? "dnd" : "off");
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: powerTile

                                width: (parent.width - parent.columnSpacing) / 2
                                height: quickControlsPage.tileHeight
                                radius: 14
                                color: controlCenter.quickHasPowerCapability ? "#1a2434" : "#171d28"
                                border.width: 0
                                opacity: controlCenter.quickHasPowerCapability ? 1 : 0.55
                                scale: powerTileTap.pressed ? 0.985 : 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: controlCenter.quickAnimStateMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: controlCenter.quickAnimTapMs
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    id: powerTileTap

                                    anchors.fill: parent
                                    enabled: controlCenter.quickHasPowerCapability
                                    onClicked: controlCenter.quickOpenDetail("power")
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#2a3548"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            iconName: controlCenter.quickPowerProfileIcon(controlCenter.quickPowerProfile)
                                        }
                                    }

                                    Column {
                                        width: parent.width - 22 - 40 - parent.spacing * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            text: "Power"
                                            color: "#e7eef9"
                                            font.pixelSize: 10
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: controlCenter.quickPowerSubtitle
                                            color: "#9eb0c6"
                                            font.pixelSize: 8
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickHasPowerProfileCapability ? "#3d81e0" : "#2a3548"
                                        border.width: 0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 11
                                            height: 11
                                            iconName: controlCenter.quickHasPowerProfileCapability
                                                ? controlCenter.quickPowerProfileIcon(controlCenter.quickPowerProfile)
                                                : "power"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: controlCenter.quickHasPowerProfileCapability
                                            onClicked: {
                                                mouse.accepted = true;
                                                controlCenter.quickCyclePowerProfile();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: controlCenter.quickHasBrightnessCapability
                        width: parent.width
                        height: visible ? quickControlsPage.sliderHeight : 0
                        radius: 14
                        color: "#151c27"
                        border.width: 0

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            LucideIcon {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                iconName: "sun"
                            }

                            Text {
                                width: 56
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Display"
                                color: "#e7eef9"
                                font.pixelSize: 11
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }

                            Slider {
                                id: brightnessSlider

                                width: parent.width - 14 - 56 - 34 - parent.spacing * 3
                                anchors.verticalCenter: parent.verticalCenter
                                from: 0
                                to: 1
                                enabled: controlCenter.quickHasBrightnessCapability
                                value: controlCenter.quickBrightnessUi

                                onPressedChanged: {
                                    controlCenter.quickBrightnessDragging = pressed;
                                }

                                onMoved: controlCenter.quickSetBrightness(value)

                                background: Rectangle {
                                    x: 0
                                    y: parent.height / 2 - height / 2
                                    width: parent.availableWidth
                                    height: 8
                                    radius: 4
                                    color: "#232f41"

                                    Rectangle {
                                        width: parent.width * brightnessSlider.visualPosition
                                        height: parent.height
                                        radius: parent.radius
                                        color: "#5f9fff"
                                    }
                                }

                                handle: Rectangle {
                                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: brightnessSlider.pressed ? "#ffffff" : "#f6faff"
                                    border.width: 0
                                }
                            }

                            Text {
                                width: 34
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(controlCenter.quickBrightnessUi * 100) + "%"
                                color: "#9eb0c6"
                                font.pixelSize: 9
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: quickControlsPage.sliderHeight
                        radius: 14
                        color: "#151c27"
                        border.width: 0
                        opacity: controlCenter.quickHasVolumeCapability ? 1 : 0.6

                        MouseArea {
                            anchors.fill: parent
                            enabled: controlCenter.quickHasVolumeCapability
                            onClicked: controlCenter.quickOpenDetail("audio")
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            LucideIcon {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                iconName: Audio.sink && Audio.sink.audio && Audio.sink.audio.muted ? "volume-x" : "volume-2"
                            }

                            Text {
                                width: 56
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Sound"
                                color: "#e7eef9"
                                font.pixelSize: 11
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }

                            Slider {
                                id: volumeSlider

                                width: parent.width - 14 - 56 - 34 - parent.spacing * 3
                                anchors.verticalCenter: parent.verticalCenter
                                from: 0
                                to: 1
                                enabled: controlCenter.quickHasVolumeCapability
                                value: controlCenter.quickVolumeUi

                                onPressedChanged: {
                                    controlCenter.quickVolumeDragging = pressed;
                                }

                                onMoved: controlCenter.quickSetVolume(value)

                                background: Rectangle {
                                    x: 0
                                    y: parent.height / 2 - height / 2
                                    width: parent.availableWidth
                                    height: 8
                                    radius: 4
                                    color: "#232f41"

                                    Rectangle {
                                        width: parent.width * volumeSlider.visualPosition
                                        height: parent.height
                                        radius: parent.radius
                                        color: "#5f9fff"
                                    }
                                }

                                handle: Rectangle {
                                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: volumeSlider.pressed ? "#ffffff" : "#f6faff"
                                    border.width: 0
                                }
                            }

                            Text {
                                width: 34
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(controlCenter.quickVolumeUi * 100) + "%"
                                color: "#9eb0c6"
                                font.pixelSize: 9
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Rectangle {
                        visible: controlCenter.quickContextFooter !== ""
                        width: parent.width
                        height: visible ? quickControlsPage.footerHeight : 0
                        radius: 11
                        color: "#10161f"
                        border.width: 0

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: controlCenter.quickContextFooter
                            color: "#8ea1b8"
                            font.pixelSize: 9
                            font.family: textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    id: quickDetailSheet

                    anchors.fill: parent
                    z: 20
                    radius: 16
                    color: "#0f141d"
                    border.width: 0
                    property bool detailOpen: controlCenter.quickDetailPanel !== ""
                    visible: detailOpen || opacity > 0.01
                    opacity: detailOpen ? 1 : 0
                    scale: detailOpen ? 1 : 0.992
                    y: detailOpen ? 0 : 2

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 115
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: controlCenter.quickAnimStateMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: controlCenter.quickAnimStateMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        hoverEnabled: true
                        preventStealing: true
                        onPressed: mouse => mouse.accepted = true
                        onReleased: mouse => mouse.accepted = true
                        onClicked: mouse => mouse.accepted = true
                        onWheel: wheel => wheel.accepted = true
                    }

                    Column {
                        z: 1
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Row {
                            width: parent.width
                            height: 22
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 22
                                radius: 11
                                color: "#1a2432"
                                border.width: 0

                                LucideIcon {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    iconName: "chevron-left"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: controlCenter.quickCloseDetail()
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: controlCenter.quickDetailPanel === "network"
                                    ? "Network"
                                    : (controlCenter.quickDetailPanel === "bluetooth"
                                        ? "Bluetooth"
                                        : (controlCenter.quickDetailPanel === "focus"
                                            ? "Focus"
                                            : (controlCenter.quickDetailPanel === "power" ? "Power" : "Sound")))
                                color: "#e7eef9"
                                font.pixelSize: 12
                                font.family: textFontFamily
                                font.weight: Font.DemiBold
                            }
                        }

                        Flickable {
                            id: quickDetailFlick

                            width: parent.width
                            height: parent.height - 22 - parent.spacing
                            clip: true
                            boundsBehavior: Flickable.DragOverBounds
                            contentWidth: width
                            contentHeight: quickDetailLoader.item ? Math.max(height, quickDetailLoader.item.implicitHeight) : height
                            interactive: contentHeight > height

                            Loader {
                                id: quickDetailLoader

                                width: quickDetailFlick.width
                                sourceComponent: controlCenter.quickDetailPanel === "network"
                                    ? networkDetailComponent
                                    : (controlCenter.quickDetailPanel === "bluetooth"
                                        ? bluetoothDetailComponent
                                        : (controlCenter.quickDetailPanel === "focus"
                                            ? focusDetailComponent
                                            : (controlCenter.quickDetailPanel === "power"
                                                ? powerDetailComponent
                                                : audioDetailComponent)))
                            }
                        }
                    }

                    Component {
                        id: networkDetailComponent

                        Column {
                            width: quickDetailLoader.width
                            spacing: 7

                            Rectangle {
                                width: parent.width
                                height: 66
                                radius: 12
                                color: "#151c27"
                                border.width: 0
                                opacity: controlCenter.quickHasWifiCapability ? 1 : 0.6

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.top: parent.top
                                    anchors.topMargin: 9
                                    spacing: 8

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: "#2d4f80"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            iconName: controlCenter.quickWifiUiEnabled ? "wifi" : "wifi-off"
                                        }
                                    }

                                    Column {
                                        width: parent.width - 22 - 40 - parent.spacing * 2
                                        spacing: 0

                                        Text {
                                            text: "Wi-Fi"
                                            color: "#e7eef9"
                                            font.pixelSize: 10
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: controlCenter.quickNetworkSubtitle
                                            color: "#9eb0c6"
                                            font.pixelSize: 8
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickCanToggleWifi && controlCenter.quickWifiUiEnabled ? "#3d81e0" : "#2a3548"
                                        border.width: 0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: controlCenter.quickCanToggleWifi && controlCenter.quickWifiUiEnabled ? (parent.width - width - 2) : 2
                                            color: "#edf5ff"

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: controlCenter.quickAnimStateMs
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: controlCenter.quickCanToggleWifi
                                            onClicked: controlCenter.quickToggleNetwork()
                                        }
                                    }
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 8
                                    spacing: 6

                                    Rectangle {
                                        width: Math.floor((parent.width - parent.spacing) / 2)
                                        height: 20
                                        radius: 10
                                        color: "#202938"

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            LucideIcon {
                                                width: 10
                                                height: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                iconName: "globe"
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: controlCenter.quickNetworkConnectivity
                                                color: controlCenter.quickNetworkConnectivity === "No internet" ? "#f2c17a" : "#a7b8cc"
                                                font.pixelSize: 7
                                                font.family: textFontFamily
                                                font.weight: Font.Medium
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width - Math.floor((parent.width - parent.spacing) / 2) - parent.spacing
                                        height: 20
                                        radius: 10
                                        color: "#202938"

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            LucideIcon {
                                                width: 10
                                                height: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                iconName: "signal"
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: controlCenter.quickNetworkSignalStrength + "%"
                                                color: "#a7b8cc"
                                                font.pixelSize: 7
                                                font.family: textFontFamily
                                                font.weight: Font.Medium
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: controlCenter.quickHasWifiCapability ? Math.min(5, Network.friendlyWifiNetworks.length) : 0

                                delegate: Rectangle {
                                    required property int index

                                    readonly property var net: Network.friendlyWifiNetworks[index]
                                    width: quickDetailLoader.width
                                    height: 36
                                    radius: 11
                                    color: net && net.active ? "#1a2a43" : "#151c27"
                                    border.width: 0
                                    scale: networkRowTap.pressed ? 0.988 : 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: controlCenter.quickAnimStateMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: controlCenter.quickAnimTapMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: net && net.active ? "#2f68b2" : "#243044"

                                            LucideIcon {
                                                anchors.centerIn: parent
                                                width: 11
                                                height: 11
                                                iconName: net && net.active ? "wifi" : "wifi-off"
                                            }
                                        }

                                        Column {
                                            width: parent.width - 20 - 64 - parent.spacing * 2
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 0

                                            Text {
                                                text: net && net.ssid ? net.ssid : "Unknown"
                                                color: "#e7eef9"
                                                font.pixelSize: 9
                                                font.family: textFontFamily
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: (net && net.active ? "Connected" : (net && net.security ? "Secured" : "Open"))
                                                    + (net && net.strength >= 0 ? (" · " + Math.round(net.strength) + "%") : "")
                                                color: "#97a9c0"
                                                font.pixelSize: 7
                                                font.family: textFontFamily
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            width: 64
                                            height: 20
                                            radius: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: net && net.active ? "#3d81e0" : "#2a3548"
                                            border.width: 0

                                            Text {
                                                anchors.centerIn: parent
                                                text: net && net.active ? "Disconnect" : "Connect"
                                                color: "#e8f1fb"
                                                font.pixelSize: 7
                                                font.family: textFontFamily
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: networkRowTap

                                        anchors.fill: parent
                                        onClicked: {
                                            if (!net)
                                                return;
                                            if (net.active)
                                                Network.disconnectWifiNetwork();
                                            else
                                                Network.connectToWifiNetwork(net);
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: quickDetailLoader.width
                                height: 30
                                radius: 10
                                visible: !controlCenter.quickHasWifiCapability
                                color: "#151c27"
                                border.width: 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "Network controls unavailable"
                                    color: "#9eb0c6"
                                    font.pixelSize: 9
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    Component {
                        id: bluetoothDetailComponent

                        Column {
                            spacing: 7

                            Rectangle {
                                width: quickDetailLoader.width
                                height: 34
                                radius: 12
                                color: "#151c27"
                                border.width: 0
                                opacity: controlCenter.quickHasBluetoothCapability ? 1 : 0.6

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        text: "Bluetooth"
                                        color: "#e7eef9"
                                        font.pixelSize: 10
                                        font.family: textFontFamily
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickBluetoothUiEnabled ? "#3d81e0" : "#2a3548"
                                        border.width: 0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: controlCenter.quickBluetoothUiEnabled ? (parent.width - width - 2) : 2
                                            color: "#edf5ff"

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: controlCenter.quickAnimStateMs
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: controlCenter.quickHasBluetoothCapability
                                            onClicked: controlCenter.quickToggleBluetooth()
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: controlCenter.quickHasBluetoothCapability ? Math.min(5, BluetoothStatus.friendlyDeviceList.length) : 0

                                delegate: Rectangle {
                                    required property int index

                                    readonly property var device: BluetoothStatus.friendlyDeviceList[index]
                                    width: quickDetailLoader.width
                                    height: 32
                                    radius: 11
                                    color: device && device.connected ? "#1a2a43" : "#151c27"
                                    border.width: 0
                                    scale: bluetoothRowTap.pressed ? 0.988 : 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: controlCenter.quickAnimStateMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: controlCenter.quickAnimTapMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 9
                                        anchors.rightMargin: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            width: parent.width - 70
                                            text: device && device.name ? device.name : "Unknown"
                                            color: "#e7eef9"
                                            font.pixelSize: 9
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            width: 58
                                            height: 20
                                            radius: 10
                                            color: device && device.connected ? "#3d81e0" : "#2a3548"
                                            border.width: 0

                                            Text {
                                                anchors.centerIn: parent
                                                text: device && device.connected ? "Disconnect" : "Connect"
                                                color: "#e8f1fb"
                                                font.pixelSize: 7
                                                font.family: textFontFamily
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: bluetoothRowTap

                                        anchors.fill: parent
                                        onClicked: {
                                            if (!device)
                                                return;
                                            if (device.connected)
                                                device.disconnect();
                                            else if (device.paired)
                                                device.connect();
                                            else
                                                device.pair();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: quickDetailLoader.width
                                height: 30
                                radius: 10
                                visible: !controlCenter.quickHasBluetoothCapability
                                color: "#151c27"
                                border.width: 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "Bluetooth unavailable"
                                    color: "#9eb0c6"
                                    font.pixelSize: 9
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    Component {
                        id: focusDetailComponent

                        Column {
                            width: quickDetailLoader.width
                            spacing: 7

                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 11
                                color: "#151c27"
                                border.width: 0

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 7

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#2a3548"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 11
                                            height: 11
                                            iconName: controlCenter.quickFocusModeIcon(controlCenter.quickFocusMode)
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Focus: " + controlCenter.quickFocusModeLabel(controlCenter.quickFocusMode)
                                        color: "#e7eef9"
                                        font.pixelSize: 10
                                        font.family: textFontFamily
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Grid {
                                width: parent.width
                                columns: 2
                                rowSpacing: 7
                                columnSpacing: 7

                                Repeater {
                                    model: [
                                        { key: "off", label: "Off", icon: "bell-off" },
                                        { key: "dnd", label: "DND", icon: "moon" },
                                        { key: "work", label: "Work", icon: "briefcase" },
                                        { key: "meeting", label: "Meeting", icon: "calendar" },
                                        { key: "gaming", label: "Gaming", icon: "gamepad-2" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData

                                        readonly property string modeKey: String(modelData.key)
                                        readonly property bool active: controlCenter.quickFocusMode === modeKey
                                        width: (quickDetailLoader.width - 7) / 2
                                        height: 38
                                        radius: 11
                                        color: active ? "#304d77" : "#151c27"
                                        border.width: active ? 1 : 0
                                        border.color: "#8fb5e5"
                                        scale: modeTap.pressed ? 0.97 : 1

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: controlCenter.quickAnimTapMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            LucideIcon {
                                                width: 12
                                                height: 12
                                                anchors.verticalCenter: parent.verticalCenter
                                                iconName: String(modelData.icon)
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: String(modelData.label)
                                                color: "#e7eef9"
                                                font.pixelSize: 9
                                                font.family: textFontFamily
                                                font.weight: active ? Font.Bold : Font.DemiBold
                                            }
                                        }

                                        MouseArea {
                                            id: modeTap

                                            anchors.fill: parent
                                            onClicked: controlCenter.quickSetFocusMode(modeKey)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: powerDetailComponent

                        Column {
                            width: quickDetailLoader.width
                            spacing: 7

                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 11
                                color: "#151c27"
                                border.width: 0

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 7

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#2a3548"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 11
                                            height: 11
                                            iconName: "power"
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: controlCenter.quickPowerSubtitle
                                        color: "#e7eef9"
                                        font.pixelSize: 10
                                        font.family: textFontFamily
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Text {
                                text: "Performance Mode"
                                color: "#9eb0c6"
                                font.pixelSize: 8
                                font.family: textFontFamily
                                font.weight: Font.Medium
                            }

                            Row {
                                width: parent.width
                                spacing: 7

                                Repeater {
                                    model: ["power-saver", "balanced", "performance"]

                                    delegate: Rectangle {
                                        required property var modelData

                                        readonly property string profileKey: String(modelData)
                                        readonly property bool active: controlCenter.quickPowerProfile === profileKey
                                        width: (quickDetailLoader.width - 14) / 3
                                        height: 44
                                        radius: 11
                                        color: active ? "#31527f" : "#151c27"
                                        border.width: active ? 1 : 0
                                        border.color: "#8fb5e5"
                                        opacity: controlCenter.quickHasPowerProfileCapability ? 1 : 0.45
                                        scale: profileTap.pressed ? 0.97 : 1

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: controlCenter.quickAnimTapMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            LucideIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 12
                                                height: 12
                                                iconName: controlCenter.quickPowerProfileIcon(profileKey)
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: controlCenter.quickPowerProfilePretty(profileKey)
                                                color: "#e8f1fb"
                                                font.pixelSize: 7
                                                font.family: textFontFamily
                                                font.weight: active ? Font.Bold : Font.DemiBold
                                            }
                                        }

                                        MouseArea {
                                            id: profileTap

                                            anchors.fill: parent
                                            enabled: controlCenter.quickHasPowerProfileCapability
                                            onClicked: controlCenter.quickSetPowerProfile(profileKey)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 24
                                radius: 10
                                color: "#151c27"
                                border.width: 0

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: controlCenter.quickPowerProfileDescription(controlCenter.quickPowerProfile)
                                    color: "#94a7be"
                                    font.pixelSize: 8
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 11
                                color: "#151c27"
                                border.width: 0

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 7

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickNightLightUiActive ? "#5a4a2d" : "#2a3548"

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 11
                                            height: 11
                                            iconName: "moon"
                                        }
                                    }

                                    Column {
                                        width: parent.width - 20 - 40 - parent.spacing * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        Text {
                                            text: "Night Light"
                                            color: "#e7eef9"
                                            font.pixelSize: 9
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: controlCenter.quickNightLightUiActive ? "On" : "Off"
                                            color: controlCenter.quickNightLightUiActive ? "#e7c37a" : "#9eb0c6"
                                            font.pixelSize: 7
                                            font.family: textFontFamily
                                            font.weight: Font.Medium
                                        }
                                    }

                                    Rectangle {
                                        width: 40
                                        height: 20
                                        radius: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: controlCenter.quickNightLightUiActive ? "#3d81e0" : "#2a3548"

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: controlCenter.quickAnimStateMs
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: controlCenter.quickNightLightUiActive ? (parent.width - width - 2) : 2
                                            color: "#edf5ff"

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: controlCenter.quickAnimStateMs
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: controlCenter.quickToggleNightLight()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: audioDetailComponent

                        Column {
                            spacing: 7

                            Rectangle {
                                width: quickDetailLoader.width
                                height: 34
                                radius: 12
                                color: "#151c27"
                                border.width: 0

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        text: "Mic"
                                        color: "#e7eef9"
                                        font.pixelSize: 10
                                        font.family: textFontFamily
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        width: 56
                                        height: 22
                                        radius: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: (Audio.source && Audio.source.audio && !Audio.source.audio.muted) ? "#3d81e0" : "#2a3548"
                                        border.width: 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: (Audio.source && Audio.source.audio && !Audio.source.audio.muted) ? "On" : "Muted"
                                            color: "#e8f1fb"
                                            font.pixelSize: 8
                                            font.family: textFontFamily
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: Audio.toggleMicMute()
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: Math.min(5, Audio.outputDevices.length)

                                delegate: Rectangle {
                                    required property int index

                                    readonly property var node: Audio.outputDevices[index]
                                    readonly property bool active: Audio.sink === node

                                    width: quickDetailLoader.width
                                    height: 32
                                    radius: 11
                                    color: active ? "#1a2a43" : "#151c27"
                                    border.width: 0

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Audio.friendlyDeviceName(node)
                                        color: "#e7eef9"
                                        font.pixelSize: 9
                                        font.family: textFontFamily
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (node)
                                                Audio.setDefaultSink(node);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        DragHandler {
            id: pageSwipeHandler

            enabled: !controlCenter.compactMode && controlCenter.quickDetailPanel === ""
            target: null
            acceptedButtons: Qt.LeftButton
            grabPermissions: PointerHandler.CanTakeOverFromAnything | PointerHandler.ApprovesTakeOverByAnything
            xAxis.enabled: false
            yAxis.enabled: true

            property real currentDelta: 0

            onActiveChanged: {
                if (active) {
                    currentDelta = 0;
                    controlCenter.dragOffset = 0;
                    return;
                }

                const delta = currentDelta;
                if (Math.abs(delta) > controlCenter.swipeThreshold) {
                    if (delta < 0)
                        controlCenter.nextPage();
                    else
                        controlCenter.previousPage();
                }

                currentDelta = 0;
                controlCenter.dragOffset = 0;
            }

            onTranslationChanged: {
                currentDelta = translation.y;
                const overTop = controlCenter.pageIndex === 0 && currentDelta > 0;
                const overBottom = controlCenter.pageIndex === controlCenter.pageCount - 1 && currentDelta < 0;
                controlCenter.dragOffset = (overTop || overBottom) ? currentDelta * 0.22 : currentDelta;
            }
        }
    }

    Column {
        visible: !controlCenter.compactMode
            && controlCenter.pageCount > 1
            && controlCenter.pageIndex !== controlCenter.quickControlsPageIndex
            && controlCenter.quickDetailPanel === ""
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        Repeater {
            model: controlCenter.pageCount

            Rectangle {
                required property int index

                width: index === controlCenter.pageIndex ? 9 : 8
                height: width
                radius: width / 2
                color: index === controlCenter.pageIndex ? "#f2f4f8" : "#636875"
                opacity: index === controlCenter.pageIndex ? 1 : 0.74

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.InOutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 220
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
