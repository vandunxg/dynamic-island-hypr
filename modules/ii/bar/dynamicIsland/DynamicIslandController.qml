import QtQuick
import "utils/IslandPriorityResolver.js" as IslandPriorityResolver

Item {
    id: root

    required property var dynamicIslandConfig
    required property QtObject adapter
    required property QtObject stateModel
    required property bool barVisible

    property bool compactHovering: false
    property bool panelHovering: false
    property bool bridgeHovering: false
    readonly property bool hoverInside: compactHovering || panelHovering || bridgeHovering

    property bool pinned: false
    property string pinnedMode: dynamicIslandConfig.defaultMode
    property string expandedMode: dynamicIslandConfig.defaultMode
    property string baseState: stateModel.dockedIdle
    property string transientKind: "volume"

    readonly property bool enabled: !!dynamicIslandConfig.enabled && barVisible && adapter.isPreferredMonitor
    property bool expanded: false
    readonly property bool transientActive: adapter.transientVolumeActive || adapter.transientBrightnessActive
    readonly property bool hasActiveIndicator: adapter.mediaPlaying || adapter.hasUnreadNotification || adapter.latestNotificationCritical || transientActive
    readonly property string stateName: !enabled ? stateModel.hidden : (pinned ? stateModel.pinned : baseState)

    readonly property string contextKey: `${enabled}|${adapter.mediaAvailable}|${adapter.mediaPlaying}|${adapter.hasUnreadNotification}|${adapter.latestNotificationCritical}|${adapter.hasMessageLikeNotification}|${adapter.transientVolumeActive}|${adapter.transientBrightnessActive}|${hoverInside}|${pinned}|${dynamicIslandConfig.defaultMode}`

    Timer {
        id: hoverOpenTimer
        interval: Math.max(60, dynamicIslandConfig.hoverOpenDelayMs)
        repeat: false
        onTriggered: {
            if (!root.enabled || root.pinned || !root.hoverInside)
                return;
            root.open(root.resolveExpandedMode());
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Math.max(120, dynamicIslandConfig.hoverCloseDelayMs)
        repeat: false
        onTriggered: {
            if (!root.pinned && !root.hoverInside)
                root.collapse();
        }
    }

    Timer {
        id: transientTimer
        interval: Math.max(600, dynamicIslandConfig.hoverCloseDelayMs + 500)
        repeat: false
        onTriggered: {
            if (!root.pinned && !root.hoverInside)
                root.setDockedState();
        }
    }

    function sanitizeMode(mode) {
        return IslandPriorityResolver.sanitizeMode(dynamicIslandConfig.modules, dynamicIslandConfig.defaultMode, mode);
    }

    function resolveExpandedMode() {
        return IslandPriorityResolver.resolveExpandedMode({
            pinned: pinned,
            pinnedMode: pinnedMode,
            hasUrgentNotification: adapter.latestNotificationCritical,
            hasMessageLikeNotification: adapter.hasMessageLikeNotification && adapter.hasUnreadNotification,
            mediaAvailable: adapter.mediaAvailable,
            defaultMode: dynamicIslandConfig.defaultMode,
            modules: dynamicIslandConfig.modules
        });
    }

    function setDockedState() {
        hoverOpenTimer.stop();
        hoverCloseTimer.stop();
        transientTimer.stop();
        baseState = hasActiveIndicator ? stateModel.dockedActive : stateModel.dockedIdle;
    }

    function updateTransientKind() {
        transientKind = adapter.transientBrightnessActive ? "brightness" : "volume";
    }

    function triggerTransientEvent() {
        if (!transientActive || pinned)
            return;
        updateTransientKind();
        baseState = stateModel.transientEvent;
        transientTimer.restart();
    }

    function open(mode) {
        hoverOpenTimer.stop();
        hoverCloseTimer.stop();
        transientTimer.stop();

        if (!enabled)
            return;

        expandedMode = sanitizeMode(mode || resolveExpandedMode());
        baseState = stateModel.expandedStateForMode(expandedMode);
    }

    function collapse() {
        if (!enabled) {
            setDockedState();
            return;
        }
        if (transientActive) {
            triggerTransientEvent();
            return;
        }
        setDockedState();
    }

    function close() {
        pinned = false;
        collapse();
    }

    function scheduleOpenFromHover() {
        if (!enabled || pinned || expanded)
            return;
        baseState = stateModel.hoverPreview;
        hoverOpenTimer.restart();
    }

    function onHoverChanged() {
        if (!enabled)
            return;

        if (hoverInside) {
            hoverCloseTimer.stop();
            if (!expanded)
                scheduleOpenFromHover();
            return;
        }

        hoverOpenTimer.stop();
        if (!pinned && expanded)
            hoverCloseTimer.restart();
        else if (!pinned)
            setDockedState();
    }

    function setCompactHovering(value) {
        if (compactHovering === value)
            return;
        compactHovering = value;
        onHoverChanged();
    }

    function setPanelHovering(value) {
        if (panelHovering === value)
            return;
        panelHovering = value;
        onHoverChanged();
    }

    function setBridgeHovering(value) {
        if (bridgeHovering === value)
            return;
        bridgeHovering = value;
        onHoverChanged();
    }

    function handlePrimaryClick() {
        if (!enabled)
            return;

        if (!expanded) {
            open(resolveExpandedMode());
            if (dynamicIslandConfig.pinOnClick) {
                pinned = true;
                pinnedMode = expandedMode;
            }
            return;
        }

        if (dynamicIslandConfig.pinOnClick) {
            pinned = !pinned;
            if (pinned)
                pinnedMode = expandedMode;
            else if (!hoverInside)
                hoverCloseTimer.restart();
        }
    }

    function handleSecondaryClick() {
        if (pinned) {
            pinned = false;
            if (!hoverInside)
                hoverCloseTimer.restart();
            return;
        }

        close();
    }

    function onOutsideInteraction() {
        if (!pinned)
            close();
    }

    function syncFromContext() {
        if (!enabled) {
            pinned = false;
            hoverOpenTimer.stop();
            hoverCloseTimer.stop();
            transientTimer.stop();
            return;
        }

        if (pinned)
            return;

        if (transientActive && !hoverInside && !expanded) {
            triggerTransientEvent();
            return;
        }

        if (baseState === stateModel.transientEvent) {
            if (transientActive)
                transientTimer.restart();
            else
                setDockedState();
            return;
        }

        if (!expanded && !hoverInside)
            setDockedState();
    }

    function updateExpanded() {
        expanded = pinned || stateModel.isExpandedState(baseState) || baseState === stateModel.transientEvent;
    }

    onPinnedChanged: updateExpanded()
    onBaseStateChanged: updateExpanded()

    onContextKeyChanged: syncFromContext()

    Component.onCompleted: {
        updateExpanded();
        setDockedState();
        syncFromContext();
    }
}
