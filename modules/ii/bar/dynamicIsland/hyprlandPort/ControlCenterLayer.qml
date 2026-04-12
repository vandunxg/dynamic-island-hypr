import QtQuick
import Quickshell

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
    readonly property int pageCount: compactMode ? 1 : (hasFileTray ? 3 : 2)
    readonly property int fileTrayPageIndex: 0
    readonly property int weatherPageIndex: hasFileTray ? 1 : 0
    readonly property int systemPageIndex: hasFileTray ? 2 : 1
    readonly property real revealProgress: showCondition ? 1 : 0
    readonly property real swipeThreshold: 24
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

    onShowConditionChanged: {
        if (showCondition) {
            pageIndex = 0;
            dragOffset = 0;
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

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: controlCenter.compactMode ? "#00000000" : "#18ffffff"
        }
    }

    Item {
        id: viewport

        anchors.fill: parent
        anchors.leftMargin: controlCenter.compactMode ? 10 : 14
        anchors.rightMargin: controlCenter.compactMode ? 10 : 34
        anchors.topMargin: controlCenter.compactMode ? 8 : 12
        anchors.bottomMargin: controlCenter.compactMode ? 8 : 12
        clip: true

        Item {
            id: pagesTrack

            width: parent.width
            height: parent.height * controlCenter.pageCount
            y: -controlCenter.pageIndex * viewport.height + controlCenter.dragOffset

            Behavior on y {
                enabled: !pageSwipeHandler.active

                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }

            Item {
                id: fileTrayPage

                visible: controlCenter.hasFileTray
                y: viewport.height * controlCenter.fileTrayPageIndex
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

                y: viewport.height * controlCenter.weatherPageIndex + (controlCenter.weatherPageActive ? ((ambientMotion - 0.5) * 1.4) : 0)
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

            Item {
                id: systemPage

                y: viewport.height * controlCenter.systemPageIndex
                width: viewport.width
                height: viewport.height

                Column {
                    anchors.fill: parent
                    spacing: 6

                    Item {
                        width: parent.width
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: "Performance"
                            color: "#f4f6fa"
                            font.pixelSize: 16
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            text: "See your console's current performance"
                            color: "#9399a5"
                            font.pixelSize: 9
                            font.family: textFontFamily
                            font.weight: Font.Medium
                        }
                    }

                    Row {
                        id: performanceRow

                        width: parent.width
                        height: parent.height - 30 - parent.spacing
                        spacing: 8

                        Repeater {
                            model: 3

                            delegate: Item {
                                id: metricCard

                                required property int index

                                readonly property bool cpuCard: index === 0
                                readonly property bool tempCard: index === 1
                                readonly property color ringColor: cpuCard
                                    ? "#ff4b5c"
                                    : (tempCard ? "#33ce76" : "#2fcf7f")
                                readonly property string iconName: cpuCard
                                    ? "cpu"
                                    : (tempCard ? "thermometer" : "memory-stick")
                                readonly property real ringSize: Math.max(48, Math.min(56, performanceRow.height * 0.52))
                                readonly property real progressValue: cpuCard
                                    ? controlCenter.cpuLoadRatio
                                    : (tempCard ? controlCenter.cpuTempRatio : controlCenter.memoryRatio)
                                property real animatedProgress: progressValue
                                readonly property real percentageValue: animatedProgress * 100
                                readonly property string centerPercentText: tempCard
                                    ? (Math.round(percentageValue) + "%")
                                    : (cpuCard ? (Math.round(percentageValue) + "%") : (percentageValue.toFixed(1) + "%"))
                                readonly property string titleText: cpuCard
                                    ? "CPU Load"
                                    : (tempCard ? "CPU Temp" : "Memory")
                                readonly property string footerText: cpuCard
                                    ? controlCenter.cpuLoadStatus
                                    : (tempCard
                                        ? (Math.round(controlCenter.estimatedCpuTempC) + "°C • " + controlCenter.cpuTempStatus)
                                        : controlCenter.memoryUsageLabel)

                                width: (performanceRow.width - performanceRow.spacing * 2) / 3
                                height: performanceRow.height

                                onProgressValueChanged: {
                                    animatedProgress = progressValue;
                                }

                                Behavior on animatedProgress {
                                    NumberAnimation {
                                        duration: 460
                                        easing.type: Easing.InOutCubic
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

                                Item {
                                    id: ringWrap

                                    width: ringSize
                                    height: ringSize
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 3

                                    Canvas {
                                        id: ringCanvas

                                        anchors.fill: parent
                                        antialiasing: true

                                        property real currentProgress: Math.max(0, Math.min(1, parent.parent.animatedProgress))
                                        property color activeColor: parent.parent.ringColor

                                        onCurrentProgressChanged: requestPaint()
                                        onActiveColorChanged: requestPaint()
                                        onWidthChanged: requestPaint()
                                        onHeightChanged: requestPaint()

                                        onPaint: {
                                            const ctx = getContext("2d");
                                            const centerX = width / 2;
                                            const centerY = height / 2;
                                            const radius = Math.min(width, height) / 2 - 2.8;
                                            const lineWidth = 3.2;
                                            const segments = 48;
                                            const step = (Math.PI * 2) / segments;
                                            const segmentSpan = step * 0.56;

                                            ctx.clearRect(0, 0, width, height);
                                            ctx.lineWidth = lineWidth;
                                            ctx.lineCap = "round";

                                            for (let segmentIndex = 0; segmentIndex < segments; segmentIndex++) {
                                                const startAngle = -Math.PI / 2 + segmentIndex * step;
                                                const endAngle = startAngle + segmentSpan;
                                                const active = (segmentIndex + 1) / segments <= currentProgress;
                                                const inactiveColor = Qt.rgba(0.17, 0.2, 0.25, 0.58);
                                                const activeAlpha = 0.55 + 0.45 * ((segmentIndex + 1) / segments);

                                                ctx.strokeStyle = active
                                                    ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, activeAlpha)
                                                    : inactiveColor;
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
                                        border.color: "#141922"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: metricCard.centerPercentText
                                        color: metricCard.ringColor
                                        font.pixelSize: metricCard.tempCard ? 10 : 10
                                        font.family: heroFontFamily
                                        font.weight: Font.Bold
                                        font.letterSpacing: -0.15
                                    }
                                }

                                Text {
                                    anchors.top: ringWrap.bottom
                                    anchors.topMargin: 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: titleText
                                    color: "#b8bec9"
                                    font.pixelSize: 9
                                    font.family: textFontFamily
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.top: ringWrap.bottom
                                    anchors.topMargin: 20
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - 4
                                    horizontalAlignment: Text.AlignHCenter
                                    text: footerText
                                    color: cpuCard || tempCard ? "#f3f5f8" : "#d6dce7"
                                    font.pixelSize: cpuCard || tempCard ? 10 : 8
                                    font.family: textFontFamily
                                    font.weight: cpuCard || tempCard ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        DragHandler {
            id: pageSwipeHandler

            enabled: !controlCenter.compactMode
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
                controlCenter.dragOffset = (overTop || overBottom) ? currentDelta * 0.34 : currentDelta;
            }
        }
    }

    Column {
        visible: !controlCenter.compactMode && controlCenter.pageCount > 1
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
