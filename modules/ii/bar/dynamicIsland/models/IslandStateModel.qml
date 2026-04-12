import QtQuick

QtObject {
    id: root

    readonly property string hidden: "hidden"
    readonly property string dockedIdle: "docked_idle"
    readonly property string dockedActive: "docked_active"
    readonly property string hoverPreview: "hover_preview"
    readonly property string expandedHome: "expanded_home"
    readonly property string expandedMedia: "expanded_media"
    readonly property string expandedMessage: "expanded_message"
    readonly property string expandedSummary: "expanded_summary"
    readonly property string expandedNotification: "expanded_notification"
    readonly property string pinned: "pinned"
    readonly property string transientEvent: "transient_event"

    function expandedStateForMode(mode) {
        switch (mode) {
        case "media":
            return root.expandedMedia;
        case "message":
            return root.expandedMessage;
        case "summary":
            return root.expandedSummary;
        case "notification":
            return root.expandedNotification;
        case "home":
        default:
            return root.expandedHome;
        }
    }

    function isExpandedState(state) {
        return [
            root.expandedHome,
            root.expandedMedia,
            root.expandedMessage,
            root.expandedSummary,
            root.expandedNotification
        ].includes(state);
    }
}
