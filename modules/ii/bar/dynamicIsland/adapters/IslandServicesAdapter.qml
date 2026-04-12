import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services

QtObject {
    id: root

    required property var screen
    required property var dynamicIslandConfig

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int activeWorkspaceId: monitor?.activeWorkspace?.id ?? -1
    readonly property var focusedWorkspaceBiggestWindow: activeWorkspaceId > 0 ? HyprlandData.biggestWindowForWorkspace(activeWorkspaceId) : null
    readonly property string focusedAppName: focusedWorkspaceBiggestWindow?.class ?? Translation.tr("Desktop")
    readonly property bool fullscreen: !!(focusedWorkspaceBiggestWindow?.fullscreen ?? focusedWorkspaceBiggestWindow?.fullscreenClient ?? false)
    readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""
    readonly property bool isPreferredMonitor: {
        const preferredMonitor = dynamicIslandConfig.preferredMonitor ?? "active";
        if (preferredMonitor === "all")
            return true;
        return focusedMonitorName === screen?.name;
    }

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool mediaAvailable: !!activePlayer && (!!activePlayer?.trackTitle || !!activePlayer?.trackArtist || !!activePlayer?.trackArtUrl)
    readonly property bool mediaPlaying: activePlayer?.isPlaying ?? false
    readonly property bool mediaCanSeek: activePlayer?.canSeek ?? false
    readonly property string mediaTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property string mediaArtist: activePlayer?.trackArtist || Translation.tr("Unknown artist")
    readonly property string mediaArtworkUrl: activePlayer?.trackArtUrl || ""
    readonly property real mediaPosition: activePlayer?.position ?? 0
    readonly property real mediaLength: activePlayer?.length ?? 0
    readonly property real mediaProgress: mediaLength > 0 ? (mediaPosition / mediaLength) : 0
    readonly property bool mediaCanGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool mediaCanGoNext: activePlayer?.canGoNext ?? false
    readonly property bool mediaCanToggle: activePlayer?.canTogglePlaying ?? false
    readonly property bool mediaShuffleSupported: activePlayer?.shuffleSupported ?? false
    readonly property bool mediaShuffle: activePlayer?.shuffle ?? false
    readonly property bool mediaLoopSupported: activePlayer?.loopSupported ?? false
    readonly property var mediaLoopState: activePlayer?.loopState ?? MprisLoopState.None
    readonly property var mediaMetadata: activePlayer?.metadata ?? ({})
    readonly property string mediaInlineLyricsRaw: {
        let inlineLyrics = mediaMetadata["xesam:asText"];
        if (!inlineLyrics)
            inlineLyrics = mediaMetadata["xesam:comment"];
        if (Array.isArray(inlineLyrics))
            return inlineLyrics.join("\n");
        return inlineLyrics ? String(inlineLyrics) : "";
    }

    readonly property bool hasUnreadNotification: Notifications.unread > 0
    readonly property bool hasAnyNotification: Notifications.list.length > 0
    readonly property var latestNotification: hasAnyNotification ? Notifications.list[Notifications.list.length - 1] : null
    readonly property string latestNotificationTitle: latestNotification?.summary ?? Translation.tr("No new notifications")
    readonly property string latestNotificationBody: latestNotification?.body ?? Translation.tr("You're all caught up")
    readonly property string latestNotificationAppName: latestNotification?.appName ?? Translation.tr("System")
    readonly property string latestNotificationAppIcon: latestNotification?.appIcon ?? ""
    readonly property string latestNotificationImage: latestNotification?.image ?? ""
    readonly property string latestNotificationUrgency: latestNotification?.urgency ?? "normal"
    readonly property bool latestNotificationCritical: latestNotificationUrgency === "2" || latestNotificationUrgency === "critical"
    readonly property bool hasMessageLikeNotification: {
        const app = latestNotificationAppName.toLowerCase();
        const content = `${latestNotificationTitle} ${latestNotificationBody}`.toLowerCase();
        return app.includes("telegram") || app.includes("discord") || app.includes("slack") ||
            app.includes("signal") || app.includes("messages") || content.includes("message") || content.includes("mentioned");
    }

    readonly property string summaryTime: DateTime.time
    readonly property string summaryDate: DateTime.longDate
    readonly property string summaryWeatherTemp: Weather.data?.temp ?? "--"
    readonly property string summaryWeatherCity: Weather.data?.city ?? Translation.tr("Unknown")
    readonly property string summaryWeatherWind: Weather.data?.wind ?? "--"
    readonly property string summaryWeatherCode: String(Weather.data?.wCode ?? "113")
    readonly property string summaryWeatherCondition: weatherConditionLabel(summaryWeatherCode)
    readonly property bool summaryWeatherEnabled: Config.options.bar.weather.enable

    readonly property int systemCpuPercent: Math.round(Math.max(0, Math.min(1, ResourceUsage.cpuUsage ?? 0)) * 100)
    readonly property int systemMemoryPercent: Math.round(Math.max(0, Math.min(1, ResourceUsage.memoryUsedPercentage ?? 0)) * 100)
    readonly property int systemSwapPercent: Math.round(Math.max(0, Math.min(1, ResourceUsage.swapUsedPercentage ?? 0)) * 100)
    readonly property string systemMemoryUsageLabel: kbToGb(ResourceUsage.memoryUsed ?? 0)
        + " / "
        + kbToGb(ResourceUsage.memoryTotal ?? 1)
        + " GB"

    readonly property bool transientVolumeActive: GlobalStates.osdVolumeOpen
    readonly property bool transientBrightnessActive: GlobalStates.osdBrightnessOpen
    readonly property bool volumeMuted: Audio.sink?.audio?.muted ?? false
    readonly property int volumePercent: Math.round((Audio.sink?.audio?.volume ?? 0) * 100)
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property int brightnessPercent: Math.round((brightnessMonitor?.brightness ?? 0) * 100)
    readonly property bool batteryAvailable: Battery.available
    readonly property real batteryPercent: Battery.percentage ?? 0
    readonly property bool batteryIsCharging: Battery.isCharging
    readonly property bool batteryPluggedIn: Battery.isPluggedIn
    readonly property string batteryStatusString: {
        if (!batteryAvailable)
            return "Unknown";
        if (batteryIsCharging)
            return "Charging";
        if (batteryPluggedIn)
            return "Plugged";
        return "Discharging";
    }

    function togglePlaying() {
        if (mediaCanToggle)
            activePlayer.togglePlaying();
    }

    function kbToGb(kb) {
        return (Number(kb) / (1024 * 1024)).toFixed(1);
    }

    function weatherConditionLabel(weatherCode) {
        const code = String(weatherCode ?? "113");
        const mapping = {
            "113": Translation.tr("Clear"),
            "116": Translation.tr("Partly cloudy"),
            "119": Translation.tr("Cloudy"),
            "122": Translation.tr("Overcast"),
            "143": Translation.tr("Mist"),
            "176": Translation.tr("Patchy rain"),
            "179": Translation.tr("Sleet"),
            "182": Translation.tr("Light sleet"),
            "185": Translation.tr("Freezing drizzle"),
            "200": Translation.tr("Thunder"),
            "227": Translation.tr("Blowing snow"),
            "230": Translation.tr("Blizzard"),
            "248": Translation.tr("Fog"),
            "260": Translation.tr("Freezing fog"),
            "263": Translation.tr("Light drizzle"),
            "266": Translation.tr("Drizzle"),
            "281": Translation.tr("Freezing drizzle"),
            "284": Translation.tr("Heavy freezing drizzle"),
            "293": Translation.tr("Light rain"),
            "296": Translation.tr("Rain"),
            "299": Translation.tr("Heavy rain"),
            "302": Translation.tr("Heavy rain"),
            "305": Translation.tr("Rain showers"),
            "308": Translation.tr("Heavy rain showers"),
            "311": Translation.tr("Light freezing rain"),
            "314": Translation.tr("Freezing rain"),
            "317": Translation.tr("Sleet showers"),
            "320": Translation.tr("Sleet showers"),
            "323": Translation.tr("Light snow"),
            "326": Translation.tr("Snow"),
            "329": Translation.tr("Heavy snow"),
            "332": Translation.tr("Heavy snow"),
            "335": Translation.tr("Snow showers"),
            "338": Translation.tr("Heavy snow"),
            "350": Translation.tr("Ice pellets"),
            "353": Translation.tr("Light showers"),
            "356": Translation.tr("Rain showers"),
            "359": Translation.tr("Heavy showers"),
            "362": Translation.tr("Sleet showers"),
            "365": Translation.tr("Heavy sleet showers"),
            "368": Translation.tr("Light snow showers"),
            "371": Translation.tr("Heavy snow showers"),
            "374": Translation.tr("Ice pellets"),
            "377": Translation.tr("Heavy ice pellets"),
            "386": Translation.tr("Patchy thunder"),
            "389": Translation.tr("Thunderstorm"),
            "392": Translation.tr("Snow thunder"),
            "395": Translation.tr("Heavy snow thunder")
        };

        return mapping[code] ?? Translation.tr("Weather");
    }

    function previousTrack() {
        if (mediaCanGoPrevious)
            activePlayer.previous();
    }

    function nextTrack() {
        if (mediaCanGoNext)
            activePlayer.next();
    }

    function seekTo(seconds) {
        if (!mediaCanSeek || mediaLength <= 0)
            return;
        activePlayer.position = Math.max(0, Math.min(seconds, mediaLength));
    }

    function toggleShuffle() {
        if (!mediaShuffleSupported)
            return;
        activePlayer.shuffle = !mediaShuffle;
    }

    function cycleLoopState() {
        if (!mediaLoopSupported)
            return;
        if (mediaLoopState === MprisLoopState.None)
            activePlayer.loopState = MprisLoopState.Track;
        else if (mediaLoopState === MprisLoopState.Track)
            activePlayer.loopState = MprisLoopState.Playlist;
        else
            activePlayer.loopState = MprisLoopState.None;
    }

    function toggleOverview() {
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }

    function toggleLeftSidebar() {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    function toggleRightSidebar() {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
    }

    function toggleMediaControls() {
        GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
    }

    function openNotificationCenter() {
        Notifications.timeoutAll();
        GlobalStates.sidebarRightOpen = true;
    }

    function dismissLatestNotification() {
        if (latestNotification != null)
            Notifications.discardNotification(latestNotification.notificationId);
    }
}
