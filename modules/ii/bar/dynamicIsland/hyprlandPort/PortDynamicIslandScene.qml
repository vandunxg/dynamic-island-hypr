import QtCore
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services

Item {
    id: root

    required property QtObject controller
    required property QtObject adapter
    required property var dynamicIslandConfig

    property alias inputMask: inputMaskItem
    property bool fileDropHover: false
    property bool fileDropFadingOut: false
    property bool fileDropCancelClosing: false
    readonly property bool fileDropUiVisible: fileDropHover || fileDropFadingOut
    property string fileDropTarget: "tray"
    property var pendingConvertPaths: []
    property bool fileConvertPickerActive: false
    property bool fileConvertBusy: false
    property bool fileConvertDone: false
    property bool fileConvertFailed: false
    property string fileConvertTargetFormat: ""
    readonly property bool fileConvertUiVisible: fileConvertPickerActive || fileConvertBusy || fileConvertDone || fileConvertFailed
    readonly property real fileDropTrayRatio: 0.5
    readonly property bool monitorFocused: adapter.monitor ? !!adapter.monitor.focused : false
    property string overviewPhase: "closed"
    readonly property bool overviewPreparing: overviewPhase === "preparing"
    readonly property bool overviewVisible: overviewPhase === "opening" || overviewPhase === "open"
    readonly property bool overviewContentVisible: overviewPhase === "open"
    readonly property bool overviewLoaderActive: overviewPhase !== "closed"
    readonly property bool keyboardFocusActive: overviewVisible && monitorFocused
    readonly property bool focusGrabActive: overviewLoaderActive
        || islandContainer.islandState === "expanded"
        || islandContainer.islandState === "control_center"
    readonly property real overviewWallpaperScale: Config.options.overview.scale
    readonly property real overviewWallpaperCacheScaleMultiplier: 1.75
    readonly property int overviewWallpaperTargetWidth: {
        const monitorWidth = adapter.monitor && adapter.monitor.width ? adapter.monitor.width : (adapter.screen ? adapter.screen.width : 1920);
        const monitorScale = adapter.monitor && adapter.monitor.scale ? adapter.monitor.scale : 1;
        const workspaceWidth = Math.max(180, monitorWidth * overviewWallpaperScale / monitorScale);
        return Math.max(1, Math.round(workspaceWidth * overviewWallpaperCacheScaleMultiplier));
    }
    readonly property int overviewWallpaperTargetHeight: {
        const monitorHeight = adapter.monitor && adapter.monitor.height ? adapter.monitor.height : (adapter.screen ? adapter.screen.height : 1080);
        const monitorScale = adapter.monitor && adapter.monitor.scale ? adapter.monitor.scale : 1;
        const workspaceHeight = Math.max(120, monitorHeight * overviewWallpaperScale / monitorScale);
        return Math.max(1, Math.round(workspaceHeight * overviewWallpaperCacheScaleMultiplier));
    }
    readonly property real overviewCapsuleWidth: islandContainer.overviewView ? islandContainer.overviewView.width : 760
    readonly property real overviewCapsuleHeight: islandContainer.overviewView ? islandContainer.overviewView.height : 308
    readonly property real overviewCapsuleRadius: islandContainer.overviewView
        ? islandContainer.overviewView.largeWorkspaceRadius + islandContainer.overviewView.outerPadding
        : 44
    readonly property color overviewCapsuleColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardColor
        : "#ee17181b"
    readonly property color overviewCapsuleBorderColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardBorderColor
        : "#33ffffff"
    readonly property real monitorWidth: adapter.monitor && adapter.monitor.width
        ? adapter.monitor.width
        : (adapter.screen ? adapter.screen.width : 1920)
    readonly property real idleCapsuleWidth: Math.max(126, Math.min(182, monitorWidth * 0.073))
    readonly property real idleCapsuleHeight: 30
    readonly property real mediaCompactWidth: Math.round(idleCapsuleWidth * 1.45)
    readonly property real mediaCompactHeight: 40
    readonly property real expandedMediaWidth: Math.max(352, Math.min(560, monitorWidth * 0.19))
    readonly property real expandedMediaHeight: Math.max(162, Math.min(236, expandedMediaWidth * 0.46))
    readonly property real dragChoiceCompactWidth: Math.max(392, Math.min(468, monitorWidth * 0.215))
    readonly property real dragChoiceCompactHeight: 96
    readonly property real convertPickerCompactWidth: Math.max(420, Math.min(500, dragChoiceCompactWidth + 28))
    readonly property real convertPickerCompactHeight: 108
    readonly property real dragChoiceCompactRadius: 28

    function beginOverviewOpening() {
        if (!overviewPreparing)
            return;
        overviewPhase = "opening";
        overviewRevealTimer.restart();
    }

    function openOverview() {
        if (overviewLoaderActive)
            return;
        overviewPhase = "preparing";
        if (overviewLoader.status === Loader.Ready)
            beginOverviewOpening();
    }

    function closeOverview() {
        if (!overviewLoaderActive)
            return;
        overviewRevealTimer.stop();
        islandContainer.restoreRestingCapsule(true);
        overviewPhase = "closed";
    }

    function openOverviewEverywhere() {
        GlobalStates.dynamicIslandOverviewOpen = true;
    }

    function closeOverviewEverywhere() {
        GlobalStates.dynamicIslandOverviewOpen = false;
    }

    function toggleOverviewEverywhere() {
        GlobalStates.dynamicIslandOverviewOpen = !GlobalStates.dynamicIslandOverviewOpen;
    }

    function prewarmWallpaperCache() {
        overviewWallpaperCache.refreshNow();
    }

    function extractDropUrls(dropEvent) {
        const urls = [];
        if (!dropEvent)
            return urls;

        function pushCandidate(value) {
            const text = String(value === undefined || value === null ? "" : value).trim();
            if (text === "")
                return;

            let normalized = text;

            if (normalized.startsWith("QUrl(\"") && normalized.endsWith("\")"))
                normalized = normalized.slice(6, -2);
            else if (normalized.startsWith("QUrl(") && normalized.endsWith(")"))
                normalized = normalized.slice(5, -1).replace(/^\"|\"$/g, "");

            normalized = normalized.replace(/\u0000/g, "").trim();
            if (normalized !== "")
                urls.push(normalized);
        }

        function pushMany(rawText) {
            const text = String(rawText === undefined || rawText === null ? "" : rawText);
            if (text.trim() === "")
                return;

            const lines = text.split(/\r?\n/);
            for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
                const line = lines[lineIndex].trim();
                if (line === "")
                    continue;
                pushCandidate(line);
            }
        }

        if (dropEvent.urls && dropEvent.urls.length !== undefined) {
            for (let index = 0; index < dropEvent.urls.length; index++) {
                pushCandidate(dropEvent.urls[index]);
            }
        }

        if (dropEvent.getDataAsString) {
            pushMany(dropEvent.getDataAsString("text/uri-list"));
            pushMany(dropEvent.getDataAsString("text/plain"));
        }

        if (dropEvent.text)
            pushMany(dropEvent.text);

        const fileUrls = urls
            .map(url => String(url || "").trim())
            .filter(url => url.startsWith("file://") || url.startsWith("/"));

        return Array.from(new Set(fileUrls));
    }

    function currentDropTarget(dragX) {
        const width = mainCapsule && mainCapsule.width ? mainCapsule.width : 1;
        const clampedX = Math.max(0, Math.min(width, dragX));
        const split = width * fileDropTrayRatio;
        return clampedX <= split ? "tray" : "convert";
    }

    function dropEventX(eventObj, fallbackValue) {
        if (eventObj && eventObj.x !== undefined)
            return Number(eventObj.x);

        if (eventObj && eventObj.position && eventObj.position.x !== undefined)
            return Number(eventObj.position.x);

        if (fallbackValue !== undefined)
            return Number(fallbackValue);

        return NaN;
    }

    function normalizeLocalPath(value) {
        const path = FileTray.localPath(value);
        return String(path || "").trim();
    }

    function convertDroppedFiles(urls) {
        const localPaths = urls
            .map(url => normalizeLocalPath(url))
            .filter(path => path !== "");

        if (localPaths.length === 0 || convertProcess.running || fileConvertBusy)
            return false;

        pendingConvertPaths = localPaths;
        fileConvertPickerActive = true;
        fileConvertBusy = false;
        fileConvertDone = false;
        fileConvertFailed = false;
        fileConvertTargetFormat = "";
        return true;
    }

    function startConvertWithTarget(targetFormat) {
        if (convertProcess.running || pendingConvertPaths.length === 0)
            return;

        const requested = String(targetFormat || "").trim().toLowerCase();
        if (requested === "")
            return;

        const normalizedTarget = requested === "jpeg" ? "jpg" : requested;
        const allowedTargets = ["png", "jpg", "pdf", "webp", "zip"];
        if (allowedTargets.indexOf(normalizedTarget) === -1)
            return;

        fileConvertTargetFormat = normalizedTarget;
        fileConvertPickerActive = false;
        fileConvertBusy = true;
        fileConvertDone = false;
        fileConvertFailed = false;

        const script = [
            "target=$1",
            "shift",
            "target=$(printf '%s' \"$target\" | tr '[:upper:]' '[:lower:]')",
            "[ \"$target\" = \"jpeg\" ] && target=jpg",
            "for src in \"$@\"; do",
            "  [ -e \"$src\" ] || continue",
            "  dir=$(dirname \"$src\")",
            "  base=$(basename \"$src\")",
            "  name=${base%.*}",
            "  ext=${base##*.}",
            "  lower=$(printf '%s' \"$ext\" | tr '[:upper:]' '[:lower:]')",
            "  [ \"$base\" = \"$name\" ] && lower=",
            "  stamp=$(date +%s%N | cut -b1-13)",
            "  out=",
            "  is_video=0",
            "  case \"$lower\" in mp4|mkv|mov|webm|avi|flv|wmv|m4v) is_video=1 ;; esac",
            "  is_office=0",
            "  case \"$lower\" in doc|docx|odt|rtf|ppt|pptx|odp|xls|xlsx|ods) is_office=1 ;; esac",
            "  if [ -d \"$src\" ]; then",
            "    if [ \"$target\" = \"zip\" ] && command -v zip >/dev/null 2>&1; then",
            "      out=\"$dir/${base}-converted-${stamp}.zip\"",
            "      (cd \"$dir\" && zip -rq \"$out\" \"$base\") >/dev/null 2>&1 || out=",
            "    fi",
            "  else",
            "    case \"$target\" in",
            "      zip)",
            "        if command -v zip >/dev/null 2>&1; then",
            "          out=\"$dir/${name}-converted-${stamp}.zip\"",
            "          (cd \"$dir\" && zip -rq \"$out\" \"$base\") >/dev/null 2>&1 || out=",
            "        fi",
            "        ;;",
            "      pdf)",
            "        if [ \"$is_office\" -eq 1 ] && command -v libreoffice >/dev/null 2>&1; then",
            "          generated=\"$dir/${name}.pdf\"",
            "          libreoffice --headless --convert-to pdf --outdir \"$dir\" \"$src\" >/dev/null 2>&1 || true",
            "          if [ -f \"$generated\" ]; then",
            "            out=\"$dir/${name}-converted-${stamp}.pdf\"",
            "            mv -f \"$generated\" \"$out\" >/dev/null 2>&1 || out=",
            "          fi",
            "        elif command -v magick >/dev/null 2>&1; then",
            "          out=\"$dir/${name}-converted-${stamp}.pdf\"",
            "          magick \"$src\" \"$out\" >/dev/null 2>&1 || out=",
            "        elif command -v convert >/dev/null 2>&1; then",
            "          out=\"$dir/${name}-converted-${stamp}.pdf\"",
            "          convert \"$src\" \"$out\" >/dev/null 2>&1 || out=",
            "        fi",
            "        ;;",
            "      png|jpg|webp)",
            "        out_ext=\"$target\"",
            "        if [ \"$is_video\" -eq 1 ] && command -v ffmpeg >/dev/null 2>&1; then",
            "          out=\"$dir/${name}-converted-${stamp}.${out_ext}\"",
            "          ffmpeg -y -loglevel error -i \"$src\" -frames:v 1 \"$out\" || out=",
            "        elif [ \"$lower\" = \"pdf\" ]; then",
            "          if command -v magick >/dev/null 2>&1; then",
            "            out=\"$dir/${name}-converted-${stamp}.${out_ext}\"",
            "            magick -density 180 \"$src[0]\" -strip \"$out\" >/dev/null 2>&1 || out=",
            "          elif [ \"$target\" = \"png\" ] && command -v pdftoppm >/dev/null 2>&1; then",
            "            prefix=\"$dir/${name}-converted-${stamp}\"",
            "            pdftoppm -png -f 1 -singlefile \"$src\" \"$prefix\" >/dev/null 2>&1 || prefix=",
            "            if [ -n \"$prefix\" ] && [ -f \"$prefix.png\" ]; then",
            "              out=\"$prefix.png\"",
            "            fi",
            "          elif [ \"$target\" = \"jpg\" ] && command -v pdftoppm >/dev/null 2>&1; then",
            "            prefix=\"$dir/${name}-converted-${stamp}\"",
            "            pdftoppm -jpeg -f 1 -singlefile \"$src\" \"$prefix\" >/dev/null 2>&1 || prefix=",
            "            if [ -n \"$prefix\" ] && [ -f \"$prefix.jpg\" ]; then",
            "              out=\"$prefix.jpg\"",
            "            fi",
            "          fi",
            "        elif command -v magick >/dev/null 2>&1; then",
            "          out=\"$dir/${name}-converted-${stamp}.${out_ext}\"",
            "          magick \"$src\" -strip \"$out\" >/dev/null 2>&1 || out=",
            "        elif command -v convert >/dev/null 2>&1; then",
            "          out=\"$dir/${name}-converted-${stamp}.${out_ext}\"",
            "          convert \"$src\" \"$out\" >/dev/null 2>&1 || out=",
            "        fi",
            "        ;;",
            "    esac",
            "  fi",
            "  emit=${out%/}",
            "  if [ -n \"$emit\" ] && [ -e \"$emit\" ]; then",
            "    esc=$(printf '%s' \"$emit\" | sed 's/%/%25/g; s/ /%20/g; s/#/%23/g; s/?/%3F/g')",
            "    if [ -d \"$emit\" ]; then",
            "      printf 'file://%s/\\n' \"$esc\"",
            "    else",
            "      printf 'file://%s\\n' \"$esc\"",
            "    fi",
            "  fi",
            "done"
        ].join("\n");

        const args = ["sh", "-lc", script, "sh", normalizedTarget];
        for (let index = 0; index < pendingConvertPaths.length; index++)
            args.push(pendingConvertPaths[index]);

        islandContainer.showControlCenter();
        convertProcess.exec(args);
    }

    function handleOutsideInteraction() {
        if (fileConvertPickerActive || fileConvertDone || fileConvertFailed) {
            convertDoneTimer.stop();
            fileConvertPickerActive = false;
            fileConvertDone = false;
            fileConvertFailed = false;
            fileConvertTargetFormat = "";
            pendingConvertPaths = [];
        }

        if (overviewLoaderActive) {
            closeOverviewEverywhere();
            return;
        }
        islandContainer.smartRestoreState();
    }

    Item {
        id: inputMaskItem
        x: mainCapsule.x
        y: mainCapsule.y
        width: mainCapsule.width
        height: mainCapsule.height + (root.focusGrabActive ? 10 : 0)
    }

    UserConfig {
        id: userConfig
    }

    QtObject {
        id: timeObj
        property string currentTime: "00:00"
        property string currentDateLabel: "Mon, Jan 01"
        readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        function padTwoDigits(value) {
            return value < 10 ? "0" + value : String(value);
        }

        function formatDateLabel(now) {
            return dayNames[now.getDay()]
                + ", "
                + monthNames[now.getMonth()]
                + " "
                + padTwoDigits(now.getDate());
        }
    }

    Timer {
        id: clockTimer
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: {
            const now = new Date();
            timeObj.currentTime = Qt.formatTime(now, "hh:mm ap");
            timeObj.currentDateLabel = timeObj.formatDateLabel(now);
            interval = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
        }
    }

    onOverviewVisibleChanged: {
        if (overviewVisible && monitorFocused)
            overviewFocusTimer.restart();
    }

    onMonitorFocusedChanged: {
        if (overviewVisible && monitorFocused)
            overviewFocusTimer.restart();
    }

    Component.onCompleted: {
        if (GlobalStates.dynamicIslandOverviewOpen)
            openOverview();
    }

    Connections {
        target: GlobalStates

        function onDynamicIslandOverviewOpenChanged() {
            if (GlobalStates.dynamicIslandOverviewOpen)
                root.openOverview();
            else
                root.closeOverview();
        }
    }

    Timer {
        id: overviewFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: overviewRevealTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "opening")
                root.overviewPhase = "open";
        }
    }

    Timer {
        id: fileTrayAutoCompactTimer
        interval: 1250
        repeat: false
        onTriggered: {
            if (islandContainer.islandState === "control_center" && !root.fileConvertUiVisible && !convertProcess.running)
                islandContainer.showTimeCapsule();
        }
    }

    Timer {
        id: fileDropExitTimer
        interval: 170
        repeat: false
        onTriggered: {
            if (!FileTray.hasEntries
                    && islandContainer.islandState === "control_center"
                    && !root.fileConvertUiVisible
                    && !convertProcess.running) {
                root.fileDropCancelClosing = true;
                islandContainer.showTimeCapsule();
                fileDropCloseResetTimer.restart();
            }
            root.fileDropFadingOut = false;
        }
    }

    Timer {
        id: fileDropCloseResetTimer
        interval: 220
        repeat: false
        onTriggered: {
            root.fileDropCancelClosing = false;
        }
    }

    Timer {
        id: convertDoneTimer
        interval: 820
        repeat: false
        onTriggered: {
            root.fileConvertDone = false;
            root.fileConvertFailed = false;
            root.fileConvertTargetFormat = "";
            pendingConvertPaths = [];

            if (islandContainer.islandState === "control_center")
                islandContainer.showTimeCapsule();
        }
    }

    Process {
        id: convertProcess

        stdout: StdioCollector {
            id: convertCollector
        }

        onExited: function(exitCode, exitStatus) {
            const lines = (convertCollector.text || "")
                .split(/\r?\n/)
                .map(line => String(line || "").trim())
                .filter(line => line.startsWith("file://"));

            const success = lines.length > 0;

            if (success)
                FileTray.addUrls(lines);

            fileDropCloseResetTimer.stop();
            root.fileDropCancelClosing = false;
            root.fileDropFadingOut = false;
            root.fileDropTarget = "tray";
            root.fileConvertPickerActive = false;
            root.fileConvertBusy = false;

            convertDoneTimer.stop();
            if (success) {
                root.fileConvertDone = true;
                root.fileConvertFailed = false;
                islandContainer.showControlCenter();
                convertDoneTimer.restart();
                return;
            }

            root.fileConvertDone = false;
            root.fileConvertFailed = true;
            islandContainer.showControlCenter();
            convertDoneTimer.restart();
        }
    }

    WallpaperThumbnailCache {
        id: overviewWallpaperCache
        sourcePath: userConfig.wallpaperPath
        targetWidth: root.overviewWallpaperTargetWidth
        targetHeight: root.overviewWallpaperTargetHeight
    }

    FocusScope {
        id: islandContainer
        anchors.fill: parent
        focus: root.overviewVisible && root.monitorFocused

        property string islandState: "normal"
        property string splitIcon: userConfig.statusIcons["default"]
        property real osdProgress: -1.0
        property bool osdProgressAnimationEnabled: true
        property string osdCustomText: ""
        property int currentWs: adapter.activeWorkspaceId > 0 ? adapter.activeWorkspaceId : 1
        property int batteryCapacity: Math.round((adapter.batteryPercent || 0) * 100)
        property bool isCharging: adapter.batteryIsCharging
        property real currentVolume: Math.max(0, Math.min(1, adapter.volumePercent / 100.0))
        property real currentBrightness: Math.max(0, Math.min(1, adapter.brightnessPercent / 100.0))
        property string notificationAppName: ""
        property string notificationSummary: ""
        property string notificationBody: ""
        property string _lastChargeStatus: adapter.batteryStatusString
        property real _lastVolumeValue: currentVolume
        property bool _lastVolumeMuted: adapter.volumeMuted
        property real _lastBrightnessValue: currentBrightness
        property real swipeTransitionProgress: 0
        property bool workspaceFromLyricsMode: false
        property bool splitFromLyricsMode: false
        property string restingState: "normal"
        property bool expandedByPlayerAutoOpen: false
        property bool pomodoroCompactForced: false
        property real lyricsCapsuleWidth: 220
        property real compactPreviewProgress: 0
        property real expandedPreviewProgress: 0
        readonly property int defaultAutoHideInterval: 1250
        readonly property int notificationAutoHideInterval: 4200
        readonly property int swipeAnimationDuration: 220
        readonly property bool blocksTransientSplit: islandState === "expanded"
            || islandState === "control_center"
            || islandState === "notification"
        readonly property bool splitShowsProgress: islandState === "split" && osdProgress >= 0
        readonly property bool splitShowsText: islandState === "split" && osdProgress < 0 && osdCustomText !== ""
        readonly property bool splitShowsIconOnly: islandState === "split" && osdProgress < 0 && osdCustomText === ""
        readonly property bool splitUsesExtendedLayout: splitShowsProgress || splitShowsText
        readonly property real splitCapsuleWidth: splitShowsProgress ? 176 : (splitShowsText ? 164 : 146)
        readonly property bool pomodoroCompactEnabled: TimerService.pomodoroRunning
            || TimerService.pomodoroBreak
            || TimerService.pomodoroCycle > 0
            || TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration
            || pomodoroCompactForced
        readonly property bool mediaCompactAvailable: islandState === "normal" && adapter.mediaAvailable
        readonly property bool pomodoroCompactAvailable: islandState === "normal" && pomodoroCompactEnabled
        readonly property bool compactCanSwipe: mediaCompactAvailable && pomodoroCompactAvailable
        readonly property bool mediaCompactVisible: mediaCompactAvailable
            && (!pomodoroCompactAvailable || compactPreviewProgress < 0.5)
        readonly property bool pomodoroCompactVisible: pomodoroCompactAvailable
            && (!mediaCompactAvailable || compactPreviewProgress >= 0.5)
        readonly property bool compactPreviewVisible: mediaCompactAvailable || pomodoroCompactAvailable
        readonly property bool expandedCanSwipe: islandState === "expanded" && adapter.mediaAvailable && pomodoroCompactEnabled
        readonly property bool expandedMediaVisible: islandState === "expanded" && (!expandedCanSwipe || expandedPreviewProgress < 0.5)
        readonly property bool expandedPomodoroVisible: islandState === "expanded" && expandedCanSwipe && expandedPreviewProgress >= 0.5
        readonly property bool canShowLyricsSwipe: adapter.mediaAvailable
            && !mediaCompactAvailable
            && (islandState === "lyrics"
                || (islandState === "long_capsule" && !workspaceFromLyricsMode))
        readonly property string lyricsDisplayText: lyricsBridge.displayText
        readonly property var overviewView: overviewLoader.item && overviewLoader.item.overviewView
            ? overviewLoader.item.overviewView
            : null

        onMediaCompactAvailableChanged: syncCompactPreviewState()
        onPomodoroCompactAvailableChanged: {
            if (pomodoroCompactAvailable && mediaCompactAvailable)
                showMediaCompactPreview();
            else
                syncCompactPreviewState();
        }
        onExpandedCanSwipeChanged: syncExpandedPreviewState()

        property real trackProgress: 0
        property string timePlayed: "0:00"
        property string timeTotal: "0:00"

        readonly property string currentTrack: adapter.mediaTitle
        readonly property string currentArtist: adapter.mediaArtist
        readonly property string currentArtUrl: adapter.mediaArtworkUrl
        readonly property var activePlayer: adapter.activePlayer

        Behavior on osdProgress {
            enabled: islandContainer.osdProgressAnimationEnabled

            SmoothedAnimation {
                velocity: 1.2
                duration: 180
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on swipeTransitionProgress {
            NumberAnimation {
                duration: capsuleMouseArea.pressed ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on compactPreviewProgress {
            NumberAnimation {
                duration: capsuleMouseArea.pressed ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on expandedPreviewProgress {
            NumberAnimation {
                duration: capsuleMouseArea.pressed ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Keys.onPressed: (event) => {
            if (!root.overviewVisible)
                return;

            if (userConfig.overviewCloseKey && event.key === userConfig.overviewCloseKey) {
                root.closeOverviewEverywhere();
                event.accepted = true;
            } else if (userConfig.overviewPreviousWorkspaceKey && event.key === userConfig.overviewPreviousWorkspaceKey) {
                Hyprland.dispatch("workspace r-1");
                event.accepted = true;
            } else if (userConfig.overviewNextWorkspaceKey && event.key === userConfig.overviewNextWorkspaceKey) {
                Hyprland.dispatch("workspace r+1");
                event.accepted = true;
            }
        }

        function handleConfiguredClickAction(actionName) {
            switch (actionName) {
            case "":
            case "none":
                return;
            case "toggleExpandedPlayer":
                if (islandState === "expanded") {
                    autoHideTimer.stop();
                    smartRestoreState();
                } else if (adapter.mediaAvailable) {
                    showExpandedPlayer(false);
                }
                return;
            case "openExpandedPlayer":
                if (adapter.mediaAvailable)
                    showExpandedPlayer(false);
                return;
            case "closeExpandedPlayer":
                if (islandState === "expanded")
                    smartRestoreState();
                return;
            case "toggleControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                else
                    showControlCenter();
                return;
            case "openControlCenter":
                showControlCenter();
                return;
            case "closeControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                return;
            case "toggleOverview":
                root.toggleOverviewEverywhere();
                return;
            case "openOverview":
                root.openOverviewEverywhere();
                return;
            case "closeOverview":
                root.closeOverviewEverywhere();
                return;
            case "toggleLyrics":
                if (restingState === "lyrics")
                    showTimeCapsule();
                else
                    showLyricsCapsule();
                return;
            case "showLyrics":
                showLyricsCapsule();
                return;
            case "showTime":
                showTimeCapsule();
                return;
            case "restoreRestingCapsule":
                smartRestoreState();
                return;
            default:
                console.warn("Unknown Dynamic Island click action:", actionName);
            }
        }

        function setOsdProgress(nextProgress, animate) {
            osdProgressAnimationReset.stop();
            osdProgressAnimationEnabled = animate;
            osdProgress = nextProgress;
            if (!animate)
                osdProgressAnimationReset.restart();
        }

        function abortLyricsTransientMode() {
            lyricsTransientRestoreTimer.stop();
            workspaceFromLyricsMode = false;
            splitFromLyricsMode = false;
        }

        function clearTransientCapsule() {
            setOsdProgress(-1.0, false);
            osdCustomText = "";
            notificationAppName = "";
            notificationSummary = "";
            notificationBody = "";
        }

        function applyRestingVisuals() {
            swipeTransitionProgress = restingState === "lyrics" ? 1 : 0;
            if (restingState === "lyrics")
                syncLyricsCapsuleWidth();
            else
                syncCompactPreviewState();
        }

        function syncCompactPreviewState() {
            if (mediaCompactAvailable && !pomodoroCompactAvailable) {
                compactPreviewProgress = 0;
                return;
            }

            if (!mediaCompactAvailable && pomodoroCompactAvailable) {
                compactPreviewProgress = 1;
                return;
            }

            if (!mediaCompactAvailable && !pomodoroCompactAvailable) {
                compactPreviewProgress = 0;
                return;
            }

            compactPreviewProgress = compactPreviewProgress >= 0.5 ? 1 : 0;
        }

        function showMediaCompactPreview() {
            compactPreviewProgress = 0;
        }

        function showPomodoroCompactPreview() {
            pomodoroCompactForced = true;
            compactPreviewProgress = 1;
        }

        function openPomodoroSetup() {
            pomodoroCompactForced = true;
            showPomodoroCompactPreview();
            Persistent.states.sidebar.bottomGroup.tab = 2;
            GlobalStates.sidebarRightOpen = true;
        }

        function syncExpandedPreviewState() {
            if (!expandedCanSwipe) {
                expandedPreviewProgress = 0;
                return;
            }

            expandedPreviewProgress = expandedPreviewProgress >= 0.5 ? 1 : 0;
        }

        function showExpandedMediaPreview() {
            expandedPreviewProgress = 0;
        }

        function showExpandedPomodoroPreview() {
            if (!expandedCanSwipe) {
                expandedPreviewProgress = 0;
                return;
            }
            expandedPreviewProgress = 1;
        }

        function restartAutoHideTimer(duration) {
            autoHideTimer.interval = duration === undefined ? defaultAutoHideInterval : duration;
            autoHideTimer.restart();
        }

        function stopAutoHideTimer() {
            autoHideTimer.stop();
            autoHideTimer.interval = defaultAutoHideInterval;
        }

        function showTransientCapsule(icon, progress, customText) {
            if (progress === undefined)
                progress = -1.0;
            if (customText === undefined)
                customText = "";

            if (blocksTransientSplit)
                return;

            const nextProgress = progress >= 0 ? progress : -1.0;
            const animateProgress = islandState === "split" && osdProgress >= 0 && nextProgress >= 0;
            const animateFromLyrics = islandState === "lyrics"
                || (islandState === "long_capsule" && workspaceFromLyricsMode)
                || (islandState === "split" && splitFromLyricsMode);

            abortLyricsTransientMode();
            splitIcon = icon;
            osdCustomText = customText;
            setOsdProgress(nextProgress, animateProgress);
            splitFromLyricsMode = animateFromLyrics;
            islandState = "split";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        function showNotificationCapsule(appName, summary, body) {
            if (root.overviewVisible || islandState === "control_center" || islandState === "expanded")
                return;

            const cleanedAppName = cleanNotificationText(appName);
            const cleanedSummary = cleanNotificationText(summary);
            const cleanedBody = cleanNotificationText(body);
            const resolvedSummary = cleanedSummary !== ""
                ? cleanedSummary
                : (cleanedBody !== "" ? cleanedBody : Translation.tr("New notification"));

            abortLyricsTransientMode();
            clearTransientCapsule();
            notificationAppName = cleanedAppName !== "" ? cleanedAppName : Translation.tr("Notification");
            notificationSummary = resolvedSummary;
            notificationBody = cleanedSummary !== "" ? cleanedBody : "";
            islandState = "notification";
            restartAutoHideTimer(notificationAutoHideInterval);
        }

        function suppressCapsuleClick() {
            capsuleMouseArea.suppressNextClick = true;
            swipeSuppressReset.restart();
        }

        function restoreRestingCapsule(forceImmediate) {
            if (forceImmediate === undefined)
                forceImmediate = false;

            if (!forceImmediate
                    && restingState === "lyrics"
                    && ((islandState === "long_capsule" && workspaceFromLyricsMode)
                        || (islandState === "split" && splitFromLyricsMode))) {
                expandedByPlayerAutoOpen = false;
                swipeTransitionProgress = 1;
                stopAutoHideTimer();
                lyricsTransientRestoreTimer.restart();
                return;
            }

            abortLyricsTransientMode();
            islandState = restingState;
            clearTransientCapsule();
            applyRestingVisuals();
            expandedByPlayerAutoOpen = false;
            stopAutoHideTimer();
        }

        function setRestingState(nextState) {
            restingState = nextState === "lyrics" ? "lyrics" : "normal";
        }

        function smartRestoreState() {
            restoreRestingCapsule();
        }

        function showRestingCapsule(nextState) {
            setRestingState(nextState);
            restoreRestingCapsule();
            stopAutoHideTimer();
        }

        function showExpandedPlayer(autoOpened) {
            if (!adapter.mediaAvailable)
                return;
            abortLyricsTransientMode();
            clearTransientCapsule();
            islandState = "expanded";
            showExpandedMediaPreview();
            syncExpandedPreviewState();
            expandedByPlayerAutoOpen = autoOpened;
            if (autoOpened)
                restartAutoHideTimer();
            else
                stopAutoHideTimer();
        }

        function showControlCenter() {
            abortLyricsTransientMode();
            clearTransientCapsule();
            islandState = "control_center";
            stopAutoHideTimer();
        }

        function showLyricsCapsule() {
            showRestingCapsule("lyrics");
        }

        function showTimeCapsule() {
            showRestingCapsule("normal");
        }

        function showWorkspaceCapsule(wsId) {
            currentWs = wsId;
            if (root.overviewVisible || islandState === "control_center" || islandState === "notification")
                return;
            const animateFromLyrics = islandState === "lyrics"
                || (islandState === "long_capsule" && workspaceFromLyricsMode)
                || (islandState === "split" && splitFromLyricsMode);
            clearTransientCapsule();
            lyricsTransientRestoreTimer.stop();
            workspaceFromLyricsMode = animateFromLyrics;
            splitFromLyricsMode = false;
            islandState = "long_capsule";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        function brightnessStatusIcon(value) {
            if (value < 0.3)
                return userConfig.statusIcons["brightnessLow"];
            if (value < 0.7)
                return userConfig.statusIcons["brightnessMedium"];
            return userConfig.statusIcons["brightnessHigh"];
        }

        function formatTime(val) {
            let num = Number(val);
            if (isNaN(num) || num <= 0)
                return "0:00";
            let totalSeconds = 0;
            if (num < 10000)
                totalSeconds = Math.floor(num);
            else if (num < 100000000)
                totalSeconds = Math.floor(num / 1000);
            else
                totalSeconds = Math.floor(num / 1000000);
            const m = Math.floor(totalSeconds / 60);
            const s = Math.floor(totalSeconds % 60);
            return m + ":" + (s < 10 ? "0" : "") + s;
        }

        function cleanLyricLineText(text) {
            return String(text === undefined || text === null ? "" : text)
                .replace(/\s+/g, " ")
                .trim();
        }

        function parsePlainLyrics(rawLyrics) {
            const source = String(rawLyrics === undefined || rawLyrics === null ? "" : rawLyrics);
            const rows = source.split(/\r?\n/);
            const parsed = [];

            for (let i = 0; i < rows.length; i++) {
                const row = rows[i].trim();
                if (row === "")
                    continue;
                if (/^\[[a-zA-Z]+:.*\]$/.test(row))
                    continue;
                const lineText = cleanLyricLineText(row.replace(/\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g, ""));
                if (lineText !== "")
                    parsed.push(lineText);
            }

            return parsed;
        }

        function cleanNotificationText(text) {
            return String(text === undefined || text === null ? "" : text)
                .replace(/<[^>]*>/g, " ")
                .replace(/&nbsp;/g, " ")
                .replace(/&amp;/g, "&")
                .replace(/&quot;/g, "\"")
                .replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">")
                .replace(/\s+/g, " ")
                .trim();
        }

        function syncLyricsCapsuleWidth() {
            lyricsCapsuleWidth = Math.max(220, Math.min(root.width - 48, swipeLyricsLayer.preferredWidth));
        }

        function triggerVolumeOsd() {
            const volumeValue = Math.max(0, Math.min(1, adapter.volumePercent / 100.0));
            const isMuted = adapter.volumeMuted;
            if (Math.abs(volumeValue - _lastVolumeValue) < 0.005 && isMuted === _lastVolumeMuted)
                return;
            _lastVolumeValue = volumeValue;
            _lastVolumeMuted = isMuted;
            currentVolume = volumeValue;
            showTransientCapsule(
                isMuted ? userConfig.statusIcons["mute"] : userConfig.statusIcons["volume"],
                volumeValue,
                ""
            );
        }

        function triggerBrightnessOsd() {
            const brightnessValue = Math.max(0, Math.min(1, adapter.brightnessPercent / 100.0));
            if (Math.abs(brightnessValue - _lastBrightnessValue) < 0.005)
                return;
            _lastBrightnessValue = brightnessValue;
            currentBrightness = brightnessValue;
            showTransientCapsule(brightnessStatusIcon(brightnessValue), brightnessValue, "");
        }

        function triggerBatteryState() {
            batteryCapacity = Math.round((adapter.batteryPercent || 0) * 100);
            isCharging = adapter.batteryIsCharging;
            if (_lastChargeStatus === "") {
                _lastChargeStatus = adapter.batteryStatusString;
                return;
            }
            if (_lastChargeStatus !== adapter.batteryStatusString) {
                if (adapter.batteryStatusString === "Charging")
                    showTransientCapsule(userConfig.statusIcons["charging"], -1.0, Translation.tr("Charging"));
                else if (adapter.batteryStatusString === "Discharging")
                    showTransientCapsule(userConfig.statusIcons["discharging"], -1.0, Translation.tr("On battery"));
            }
            _lastChargeStatus = adapter.batteryStatusString;
        }

        Timer {
            id: autoHideTimer
            interval: islandContainer.defaultAutoHideInterval
            onTriggered: islandContainer.smartRestoreState()
        }

        Timer {
            id: osdProgressAnimationReset
            interval: 0
            onTriggered: islandContainer.osdProgressAnimationEnabled = true
        }

        Timer {
            id: lyricsTransientRestoreTimer
            interval: islandContainer.swipeAnimationDuration
            onTriggered: {
                islandContainer.workspaceFromLyricsMode = false;
                islandContainer.splitFromLyricsMode = false;
                islandContainer.islandState = islandContainer.restingState;
                islandContainer.clearTransientCapsule();
                islandContainer.applyRestingVisuals();
                islandContainer.expandedByPlayerAutoOpen = false;
            }
        }

        QtObject {
            id: lyricsBridge

            readonly property string title: islandContainer.currentTrack
            readonly property string artist: islandContainer.currentArtist
            readonly property var plainLines: islandContainer.parsePlainLyrics(adapter.mediaInlineLyricsRaw)
            readonly property string plainLyric: plainLines.length > 0 ? plainLines[0] : ""
            readonly property string displayText: {
                if (title === "")
                    return Translation.tr("No music playing");
                if (plainLyric !== "")
                    return plainLyric;
                return artist !== "" && artist !== Translation.tr("Unknown artist")
                    ? title + " - " + artist
                    : title;
            }
        }

        Timer {
            id: progressPoller
            interval: 500
            running: islandContainer.activePlayer !== null && islandContainer.islandState === "expanded"
            repeat: true
            onTriggered: {
                const player = islandContainer.activePlayer;
                if (!player)
                    return;
                const currentPos = Number(player.position) || 0;
                let totalLen = Number(player.length) || 0;
                if (totalLen <= 0 && player.metadata && player.metadata["mpris:length"])
                    totalLen = Number(player.metadata["mpris:length"]);

                if (totalLen > 0) {
                    islandContainer.trackProgress = currentPos / totalLen;
                    islandContainer.timePlayed = islandContainer.formatTime(currentPos);
                    islandContainer.timeTotal = islandContainer.formatTime(totalLen);
                } else {
                    islandContainer.trackProgress = 0;
                    islandContainer.timePlayed = islandContainer.formatTime(currentPos);
                    islandContainer.timeTotal = "0:00";
                }
            }
        }

        Connections {
            target: Notifications

            function onNotify(notification) {
                islandContainer.showNotificationCapsule(notification.appName, notification.summary, notification.body);
            }
        }

        Connections {
            target: adapter

            function onActiveWorkspaceIdChanged() {
                if (adapter.activeWorkspaceId >= 1)
                    islandContainer.currentWs = adapter.activeWorkspaceId;
                if (adapter.activeWorkspaceId >= 1 && !adapter.mediaAvailable)
                    islandContainer.showWorkspaceCapsule(adapter.activeWorkspaceId);
            }

            function onMediaTitleChanged() {
                if (!adapter.mediaAvailable && islandContainer.islandState === "expanded")
                    islandContainer.smartRestoreState();
            }

            function onMediaAvailableChanged() {
                if (!adapter.mediaAvailable && islandContainer.islandState === "expanded")
                    islandContainer.smartRestoreState();
                if (!adapter.mediaAvailable && (islandContainer.islandState === "lyrics" || islandContainer.restingState === "lyrics"))
                    islandContainer.showTimeCapsule();

                if (adapter.mediaAvailable && islandContainer.islandState === "normal" && islandContainer.pomodoroCompactAvailable)
                    islandContainer.showMediaCompactPreview();

                if (adapter.mediaAvailable && islandContainer.islandState === "expanded" && islandContainer.expandedCanSwipe)
                    islandContainer.showExpandedMediaPreview();
            }

            function onVolumePercentChanged() {
                islandContainer.triggerVolumeOsd();
            }

            function onVolumeMutedChanged() {
                islandContainer.triggerVolumeOsd();
            }

            function onBrightnessPercentChanged() {
                islandContainer.triggerBrightnessOsd();
            }

            function onBatteryStatusStringChanged() {
                islandContainer.triggerBatteryState();
            }

            function onBatteryPercentChanged() {
                islandContainer.batteryCapacity = Math.round((adapter.batteryPercent || 0) * 100);
            }

            function onBatteryIsChargingChanged() {
                islandContainer.isCharging = adapter.batteryIsCharging;
            }
        }

        Component.onCompleted: {
            islandContainer._lastVolumeValue = Math.max(0, Math.min(1, adapter.volumePercent / 100.0));
            islandContainer._lastBrightnessValue = Math.max(0, Math.min(1, adapter.brightnessPercent / 100.0));
            islandContainer._lastVolumeMuted = adapter.volumeMuted;
            islandContainer.triggerBatteryState();
            islandContainer.currentWs = adapter.activeWorkspaceId > 0 ? adapter.activeWorkspaceId : 1;
            islandContainer.applyRestingVisuals();
        }
    }

    Rectangle {
        id: mainCapsule
        property int morphDuration: 250
        property real outlineWidth: root.overviewVisible
            ? 1
            : (((root.fileDropUiVisible || root.fileConvertUiVisible) && islandContainer.islandState === "control_center") ? 1.2 : 0)
        property color outlineColor: root.overviewVisible
            ? root.overviewCapsuleBorderColor
            : (((root.fileDropUiVisible || root.fileConvertUiVisible) && islandContainer.islandState === "control_center") ? "#7ad5ff" : "#00000000")
        readonly property real targetWidth: {
            if (root.overviewVisible)
                return root.overviewCapsuleWidth;

            switch (islandContainer.islandState) {
            case "normal":
                return islandContainer.compactPreviewVisible ? root.mediaCompactWidth : root.idleCapsuleWidth;
            case "split":
                return islandContainer.splitCapsuleWidth;
            case "long_capsule":
                return 220;
            case "lyrics":
                return islandContainer.lyricsCapsuleWidth;
            case "control_center":
                if (root.fileDropUiVisible)
                    return root.dragChoiceCompactWidth;
                if (root.fileConvertPickerActive)
                    return root.convertPickerCompactWidth;
                if (root.fileConvertUiVisible)
                    return root.dragChoiceCompactWidth;
                return controlCenterLayer ? controlCenterLayer.preferredCapsuleWidth : 352;
            case "expanded":
                return root.expandedMediaWidth;
            case "notification":
                return Math.max(notificationLayer.minimumWidth, Math.min(notificationLayer.maximumWidth, notificationLayer.preferredWidth));
            default:
                return 140;
            }
        }
        readonly property real targetHeight: {
            if (root.overviewVisible)
                return root.overviewCapsuleHeight;

            switch (islandContainer.islandState) {
            case "normal":
                return islandContainer.compactPreviewVisible ? root.mediaCompactHeight : root.idleCapsuleHeight;
            case "control_center":
                if (root.fileDropUiVisible)
                    return root.dragChoiceCompactHeight;
                if (root.fileConvertPickerActive)
                    return root.convertPickerCompactHeight;
                if (root.fileConvertUiVisible)
                    return root.dragChoiceCompactHeight;
                return controlCenterLayer ? controlCenterLayer.preferredCapsuleHeight : 176;
            case "expanded":
                return root.expandedMediaHeight;
            case "notification":
                return Math.max(56, Math.min(68, notificationLayer.preferredHeight));
            default:
                return 38;
            }
        }
        readonly property real targetRadius: {
            if (root.overviewVisible)
                return root.overviewCapsuleRadius;

            switch (islandContainer.islandState) {
            case "normal":
                return islandContainer.compactPreviewVisible ? 20 : 12;
            case "control_center":
                return (root.fileDropUiVisible || root.fileConvertUiVisible) ? root.dragChoiceCompactRadius : 30;
            case "expanded":
                return 32;
            case "notification":
                return mainCapsule.targetHeight / 2;
            default:
                return 19;
            }
        }
        readonly property real targetTopRadius: {
            if (root.overviewVisible)
                return root.overviewCapsuleRadius;
            if (islandContainer.islandState === "normal")
                return islandContainer.compactPreviewVisible ? 17 : 0;
            if (islandContainer.islandState === "expanded")
                return 26;
            return targetRadius;
        }

        color: root.overviewVisible ? root.overviewCapsuleColor : "black"
        y: 0
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true
        width: targetWidth
        height: targetHeight
        topLeftRadius: targetTopRadius
        topRightRadius: targetTopRadius
        bottomLeftRadius: targetRadius
        bottomRightRadius: targetRadius

        Behavior on width {
            NumberAnimation {
                duration: mainCapsule.morphDuration
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: mainCapsule.morphDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on topLeftRadius {
            NumberAnimation {
                duration: mainCapsule.morphDuration
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on topRightRadius {
            NumberAnimation {
                duration: mainCapsule.morphDuration
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on bottomLeftRadius {
            NumberAnimation {
                duration: mainCapsule.morphDuration
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on bottomRightRadius {
            NumberAnimation {
                duration: mainCapsule.morphDuration
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 280
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on outlineWidth {
            NumberAnimation {
                duration: 260
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on outlineColor {
            ColorAnimation {
                duration: 260
                easing.type: Easing.InOutQuad
            }
        }

        border.width: outlineWidth
        border.color: outlineColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(parent.radius - 1, 0)
            color: "transparent"
            border.width: 1
            border.color: "#12ffffff"
            opacity: root.overviewVisible
                ? 1
                : (((root.fileDropUiVisible || root.fileConvertUiVisible) && islandContainer.islandState === "control_center")
                    ? 0
                    : (islandContainer.islandState === "normal" && !islandContainer.compactPreviewVisible ? 0 : 0.08))

            Behavior on opacity {
                NumberAnimation {
                    duration: root.overviewVisible ? 260 : 140
                    easing.type: Easing.InOutQuad
                }
            }
        }

        MouseArea {
            id: capsuleMouseArea
            anchors.fill: parent
            enabled: !root.overviewVisible
                && !(islandContainer.islandState === "control_center"
                    && controlCenterLayer
                    && controlCenterLayer.quickDetailOpen)
            acceptedButtons: islandContainer.islandState === "control_center"
                ? userConfig.mouseButtonsMask([userConfig.dynamicIslandSecondaryButton])
                : userConfig.mouseButtonsMask([
                    userConfig.dynamicIslandSwipeButton,
                    userConfig.dynamicIslandPrimaryButton,
                    userConfig.dynamicIslandSecondaryButton
                ])
            preventStealing: true
            hoverEnabled: true

            property real swipeStartX: 0
            property real swipeStartY: 0
            property real swipeStartProgress: 0
            property string swipeMode: ""
            property bool swipeArmed: false
            property bool swipePassedThreshold: false
            property bool swipeMoved: false
            property bool suppressNextClick: false

            Timer {
                id: swipeSuppressReset
                interval: 180
                repeat: false
                onTriggered: capsuleMouseArea.suppressNextClick = false
            }

            onPressed: mouse => {
                swipeStartX = mouse.x;
                swipeStartY = mouse.y;

                const swipeButtonPressed = mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSwipeButton);
                const primaryButtonPressed = mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton);
                const secondaryButtonPressed = mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton);
                const swipeGesturePressed = swipeButtonPressed && !secondaryButtonPressed;
                const compactExpandedSwipePressed = swipeGesturePressed || primaryButtonPressed;
                swipeMode = "";

                if (compactExpandedSwipePressed && islandContainer.compactCanSwipe) {
                    swipeArmed = true;
                    swipeMode = "compact_horizontal";
                    swipeStartProgress = islandContainer.compactPreviewProgress;
                } else if (compactExpandedSwipePressed && islandContainer.expandedCanSwipe) {
                    swipeArmed = true;
                    swipeMode = "expanded_horizontal";
                    swipeStartProgress = islandContainer.expandedPreviewProgress;
                } else if (swipeGesturePressed && islandContainer.canShowLyricsSwipe) {
                    swipeArmed = true;
                    swipeMode = "lyrics_horizontal";
                    swipeStartProgress = islandContainer.islandState === "lyrics" ? 1 : 0;
                    islandContainer.swipeTransitionProgress = swipeStartProgress;
                } else {
                    swipeArmed = false;
                    swipeStartProgress = 0;
                }

                swipePassedThreshold = false;
                swipeMoved = false;
            }

            onPositionChanged: mouse => {
                if (!pressed || !swipeArmed || suppressNextClick)
                    return;

                const deltaX = mouse.x - swipeStartX;
                const deltaY = mouse.y - swipeStartY;
                const absDeltaX = Math.abs(deltaX);
                const absDeltaY = Math.abs(deltaY);

                let nextProgress = swipeStartProgress;

                if (swipeMode === "compact_horizontal") {
                    const adjustedDeltaX = absDeltaY < 24 ? deltaX : 0;
                    nextProgress = Math.max(0, Math.min(1, swipeStartProgress + adjustedDeltaX / 108));
                } else {
                    const adjustedDeltaX = absDeltaY < 24 ? deltaX : 0;
                    nextProgress = Math.max(0, Math.min(1, swipeStartProgress + adjustedDeltaX / 108));
                }

                swipeMoved = swipeMoved || absDeltaX > 6 || absDeltaY > 6;

                if (swipeMode === "compact_horizontal")
                    islandContainer.compactPreviewProgress = nextProgress;
                else if (swipeMode === "expanded_horizontal")
                    islandContainer.expandedPreviewProgress = nextProgress;
                else
                    islandContainer.swipeTransitionProgress = nextProgress;

                if (swipeStartProgress < 0.5)
                    swipePassedThreshold = nextProgress >= 0.56;
                else
                    swipePassedThreshold = nextProgress <= 0.44;
            }

            onReleased: {
                if (swipeMoved) {
                    suppressNextClick = true;
                    swipeSuppressReset.restart();
                }

                if (swipeArmed && swipePassedThreshold) {
                    if (swipeMode === "compact_horizontal") {
                        if (swipeStartProgress < 0.5)
                            islandContainer.showPomodoroCompactPreview();
                        else
                            islandContainer.showMediaCompactPreview();
                    } else if (swipeMode === "expanded_horizontal") {
                        if (swipeStartProgress < 0.5)
                            islandContainer.showExpandedPomodoroPreview();
                        else
                            islandContainer.showExpandedMediaPreview();
                    } else {
                        if (swipeStartProgress < 0.5)
                            islandContainer.showLyricsCapsule();
                        else
                            islandContainer.showTimeCapsule();
                    }
                } else {
                    if (swipeMode === "compact_horizontal")
                        islandContainer.compactPreviewProgress = swipeStartProgress;
                    else if (swipeMode === "expanded_horizontal")
                        islandContainer.expandedPreviewProgress = swipeStartProgress;
                    else
                        islandContainer.swipeTransitionProgress = swipeStartProgress;
                }

                swipeMode = "";
                swipeArmed = false;
                swipePassedThreshold = false;
                swipeMoved = false;
            }

            onCanceled: {
                swipeMode = "";
                swipeArmed = false;
                swipePassedThreshold = false;
                swipeMoved = false;
                suppressNextClick = false;
                swipeSuppressReset.stop();
                islandContainer.syncCompactPreviewState();
                islandContainer.syncExpandedPreviewState();
                islandContainer.swipeTransitionProgress = islandContainer.islandState === "lyrics" ? 1 : 0;
            }

            onClicked: mouse => {
                if (suppressNextClick) {
                    swipeSuppressReset.stop();
                    suppressNextClick = false;
                    return;
                }

                if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                    if (islandContainer.mediaCompactVisible) {
                        islandContainer.showExpandedPlayer(false);
                        return;
                    }

                    if (islandContainer.pomodoroCompactVisible || islandContainer.expandedPomodoroVisible) {
                        islandContainer.openPomodoroSetup();
                        return;
                    }

                    islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandPrimaryAction);
                    return;
                }

                if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                    if (islandContainer.islandState === "control_center")
                        islandContainer.smartRestoreState();
                    else
                        islandContainer.showControlCenter();
                }
            }
        }

        DropArea {
            id: fileDropArea

            anchors.fill: parent
            enabled: !root.overviewVisible

            onEntered: drag => {
                const urls = root.extractDropUrls(drag);
                const validDrop = urls.length > 0;
                fileDropCloseResetTimer.stop();
                fileDropExitTimer.stop();
                convertDoneTimer.stop();
                root.fileConvertDone = false;
                root.fileConvertFailed = false;
                root.fileConvertTargetFormat = "";
                root.fileDropCancelClosing = false;
                root.fileDropFadingOut = false;
                root.fileDropHover = validDrop;

                if (validDrop) {
                    const eventX = root.dropEventX(drag, mainCapsule.width * 0.5);
                    root.fileDropTarget = root.currentDropTarget(eventX);
                    fileTrayAutoCompactTimer.stop();
                    if (islandContainer.islandState !== "control_center")
                        islandContainer.showControlCenter();
                }
            }

            onPositionChanged: drag => {
                if (!root.fileDropHover)
                    return;

                const eventX = root.dropEventX(drag);
                if (!isNaN(eventX))
                    root.fileDropTarget = root.currentDropTarget(eventX);
            }

            onExited: {
                root.fileDropTarget = "tray";

                if (root.fileConvertUiVisible || convertProcess.running) {
                    root.fileDropHover = false;
                    root.fileDropCancelClosing = false;
                    root.fileDropFadingOut = false;
                    return;
                }

                if (!FileTray.hasEntries && islandContainer.islandState === "control_center") {
                    root.fileDropHover = false;
                    root.fileDropCancelClosing = false;
                    root.fileDropFadingOut = true;
                    fileDropExitTimer.restart();
                    return;
                }

                root.fileDropHover = false;
                root.fileDropCancelClosing = false;
                root.fileDropFadingOut = false;
            }

            onDropped: drop => {
                const urls = root.extractDropUrls(drop);
                const hoverTarget = root.fileDropTarget;
                fileDropCloseResetTimer.stop();
                fileDropExitTimer.stop();
                root.fileDropCancelClosing = false;
                root.fileDropFadingOut = false;
                root.fileDropHover = false;
                let target = hoverTarget;
                const fallbackX = hoverTarget === "convert" ? mainCapsule.width : 0;
                const dropX = root.dropEventX(drop, fallbackX);
                if (!isNaN(dropX))
                    target = root.currentDropTarget(dropX);
                root.fileDropTarget = "tray";

                if (urls.length === 0)
                    return;

                if (target !== "convert") {
                    convertDoneTimer.stop();
                    root.fileConvertPickerActive = false;
                    root.fileConvertDone = false;
                    root.fileConvertFailed = false;
                    root.fileConvertTargetFormat = "";
                    pendingConvertPaths = [];
                }

                if (target === "convert") {
                    const openedPicker = root.convertDroppedFiles(urls);
                    if (openedPicker || root.fileConvertUiVisible || convertProcess.running)
                        islandContainer.showControlCenter();
                } else {
                    const addedCount = FileTray.addUrls(urls);
                    if (addedCount > 0) {
                        islandContainer.showControlCenter();
                        fileTrayAutoCompactTimer.restart();
                    }
                }

                if (drop.acceptProposedAction)
                    drop.acceptProposedAction();
            }
        }

        ClockLayer {
            currentTime: timeObj.currentTime
            heroFontFamily: userConfig.timeFontFamily
            showCondition: false
            contentOffsetX: 0
        }

        Item {
            id: compactPreviewTrack

            anchors.fill: parent
            clip: true
            visible: !root.overviewVisible && islandContainer.islandState === "normal" && islandContainer.compactPreviewVisible

            MediaCompactLayer {
                currentArtUrl: islandContainer.currentArtUrl
                activePlayer: islandContainer.activePlayer
                showCondition: !root.overviewVisible && islandContainer.mediaCompactVisible
                transitionProgress: islandContainer.compactPreviewProgress
            }

            PomodoroCompactLayer {
                showCondition: !root.overviewVisible && islandContainer.pomodoroCompactVisible
                secondsLeft: TimerService.pomodoroSecondsLeft
                lapDuration: TimerService.pomodoroLapDuration
                isRunning: TimerService.pomodoroRunning
                isBreak: TimerService.pomodoroBreak
                isLongBreak: TimerService.pomodoroLongBreak
                textFontFamily: userConfig.textFontFamily
                heroFontFamily: userConfig.timeFontFamily
                transitionProgress: islandContainer.compactPreviewProgress
            }
        }

        SwipeLyricsLayer {
            id: swipeLyricsLayer
            lyricText: islandContainer.lyricsDisplayText
            timeText: timeObj.currentTime
            textFontFamily: userConfig.textFontFamily
            timeFontFamily: userConfig.timeFontFamily
            textPixelSize: 16
            minimumWidth: 220
            maximumWidth: Math.max(220, root.width - 48)
            transitionProgress: islandContainer.swipeTransitionProgress
            showSecondaryText: !islandContainer.workspaceFromLyricsMode
                && !islandContainer.splitFromLyricsMode
            showCondition: !root.overviewVisible && adapter.mediaAvailable && (islandContainer.islandState === "lyrics"
                || (islandContainer.islandState === "split" && islandContainer.splitFromLyricsMode)
                || (islandContainer.islandState === "long_capsule"
                    && (islandContainer.workspaceFromLyricsMode || islandContainer.swipeTransitionProgress > 0)))
            onPreferredWidthChanged: {
                if (islandContainer.islandState === "lyrics")
                    islandContainer.syncLyricsCapsuleWidth();
            }
        }

        SplitIconLayer {
            iconText: islandContainer.splitIcon
            iconFontFamily: userConfig.iconFontFamily
            transitionProgress: islandContainer.swipeTransitionProgress
            slideFromLyrics: islandContainer.splitFromLyricsMode
            showCondition: !root.overviewVisible && islandContainer.splitShowsIconOnly
        }

        OsdLayer {
            iconText: islandContainer.splitIcon
            progress: islandContainer.osdProgress
            customText: islandContainer.osdCustomText
            iconFontFamily: userConfig.iconFontFamily
            textFontFamily: userConfig.textFontFamily
            heroFontFamily: userConfig.heroFontFamily
            transitionProgress: islandContainer.swipeTransitionProgress
            slideFromLyrics: islandContainer.splitFromLyricsMode
            showCondition: !root.overviewVisible && islandContainer.splitUsesExtendedLayout
        }

        WorkspaceLayer {
            workspaceId: islandContainer.currentWs
            displayText: Translation.tr("Workspace %1").arg(islandContainer.currentWs)
            textFontFamily: userConfig.textFontFamily
            textPixelSize: 16
            animateVisibility: islandContainer.restingState !== "lyrics"
            transitionProgress: islandContainer.swipeTransitionProgress
            showCondition: !root.overviewVisible && islandContainer.islandState === "long_capsule"
                && (islandContainer.workspaceFromLyricsMode || islandContainer.swipeTransitionProgress < 0.001)
            slideFromLyrics: islandContainer.workspaceFromLyricsMode
        }

        ExpandedPlayerLayer {
            currentArtUrl: islandContainer.currentArtUrl
            currentTrack: islandContainer.currentTrack
            currentArtist: islandContainer.currentArtist
            timePlayed: islandContainer.timePlayed
            timeTotal: islandContainer.timeTotal
            trackProgress: islandContainer.trackProgress
            activePlayer: islandContainer.activePlayer
            iconFontFamily: userConfig.iconFontFamily
            textFontFamily: userConfig.textFontFamily
            transitionProgress: islandContainer.expandedPreviewProgress
            showCondition: !root.overviewVisible && islandContainer.expandedMediaVisible
            onControlPressed: islandContainer.suppressCapsuleClick()
        }

        PomodoroExpandedLayer {
            secondsLeft: TimerService.pomodoroSecondsLeft
            lapDuration: TimerService.pomodoroLapDuration
            isRunning: TimerService.pomodoroRunning
            isBreak: TimerService.pomodoroBreak
            isLongBreak: TimerService.pomodoroLongBreak
            cycle: TimerService.pomodoroCycle
            textFontFamily: userConfig.textFontFamily
            heroFontFamily: userConfig.timeFontFamily
            transitionProgress: islandContainer.expandedPreviewProgress
            showCondition: !root.overviewVisible && islandContainer.expandedPomodoroVisible
            onControlPressed: islandContainer.suppressCapsuleClick()
        }

        NotificationLayer {
            id: notificationLayer
            appName: islandContainer.notificationAppName
            summary: islandContainer.notificationSummary
            body: islandContainer.notificationBody
            iconText: userConfig.statusIcons["notification"]
            iconFontFamily: userConfig.iconFontFamily
            textFontFamily: userConfig.textFontFamily
            heroFontFamily: userConfig.heroFontFamily
            showCondition: !root.overviewVisible && islandContainer.islandState === "notification"
        }

        ControlCenterLayer {
            id: controlCenterLayer

            iconFontFamily: userConfig.iconFontFamily
            textFontFamily: userConfig.textFontFamily
            heroFontFamily: userConfig.heroFontFamily
            currentTime: timeObj.currentTime
            currentDateLabel: timeObj.currentDateLabel
            weatherTemp: adapter.summaryWeatherTemp
            weatherCity: adapter.summaryWeatherCity
            weatherCondition: adapter.summaryWeatherCondition
            weatherWind: adapter.summaryWeatherWind
            batteryCapacity: islandContainer.batteryCapacity
            isCharging: islandContainer.isCharging
            volumeLevel: islandContainer.currentVolume
            brightnessLevel: islandContainer.currentBrightness
            brightnessAvailable: !!adapter.brightnessMonitor && (adapter.brightnessMonitor.ready ?? false)
            cpuUsagePercent: adapter.systemCpuPercent
            memoryUsagePercent: adapter.systemMemoryPercent
            memoryUsageLabel: adapter.systemMemoryUsageLabel
            swapUsagePercent: adapter.systemSwapPercent
            currentWorkspace: islandContainer.currentWs
            currentTrack: islandContainer.currentTrack
            currentArtist: islandContainer.currentArtist
            fileTrayEntries: FileTray.entries
            fileDropActive: root.fileDropUiVisible || root.fileDropCancelClosing
            fileDropHovering: root.fileDropHover
            fileConvertPickerActive: root.fileConvertPickerActive
            fileConvertActive: root.fileConvertBusy
            fileConvertDone: root.fileConvertDone
            fileConvertFailed: root.fileConvertFailed
            fileConvertCount: root.pendingConvertPaths.length
            fileConvertTargetFormat: root.fileConvertTargetFormat
            immediateHide: root.fileDropCancelClosing
            fileDropTarget: root.fileDropTarget
            showCondition: !root.overviewVisible && islandContainer.islandState === "control_center"

            onActionTriggered: actionName => {
                if (actionName === "overview")
                    root.toggleOverviewEverywhere();
                else if (actionName === "leftSidebar")
                    adapter.toggleLeftSidebar();
                else if (actionName === "rightSidebar")
                    adapter.toggleRightSidebar();
                else if (actionName === "mediaControls")
                    adapter.toggleMediaControls();
            }

            onVolumeChanged: value => {
                if (Audio.sink && Audio.sink.audio)
                    Audio.sink.audio.volume = Math.max(0, Math.min(1, value));
            }

            onBrightnessChanged: value => {
                if (adapter.brightnessMonitor)
                    adapter.brightnessMonitor.setBrightness(Math.max(0, Math.min(1, value)));
            }

            onConvertTargetRequested: format => {
                root.startConvertWithTarget(format);
            }

            onRemoveFileRequested: fileUrl => FileTray.removeUrl(fileUrl)
            onClearFilesRequested: FileTray.clear()
        }

        Loader {
            id: overviewLoader

            anchors.fill: parent
            active: root.overviewLoaderActive
            asynchronous: false
            visible: root.overviewContentVisible

            onStatusChanged: {
                if (status === Loader.Ready && root.overviewPreparing)
                    root.beginOverviewOpening();
            }

            sourceComponent: Component {
                Item {
                    id: overviewScene

                    property alias overviewView: overviewView

                    anchors.fill: parent

                    PortHyprlandData {
                        id: hyprlandData
                    }

                    WorkspaceOverviewLayer {
                        id: overviewView

                        anchors.centerIn: parent
                        screen: adapter.screen
                        hyprlandData: hyprlandData
                        showCondition: root.overviewVisible
                        textFontFamily: userConfig.textFontFamily
                        heroFontFamily: userConfig.heroFontFamily
                        wallpaperPath: overviewWallpaperCache.effectiveSource
                        windowCornerRadius: userConfig.workspaceOverviewWindowRadius
                        onCloseRequested: root.closeOverviewEverywhere()
                    }
                }
            }
        }
    }
}
