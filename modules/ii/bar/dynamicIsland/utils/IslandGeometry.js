.pragma library

function compactHeight(config, barHeight) {
    return Math.max(24, barHeight + (config.compactExtraHeightPx || 0));
}

function expandedWidthForMode(config, mode) {
    const sizes = (config && config.sizes) || {};
    switch (mode) {
    case "home":
        return sizes.homeWidth || 620;
    case "media":
        return sizes.mediaWidth || 640;
    case "message":
        return sizes.messageWidth || 340;
    case "summary":
        return sizes.summaryWidth || 360;
    case "notification":
        return sizes.notificationWidth || 380;
    default:
        return sizes.homeWidth || 620;
    }
}

function expandedHeightForMode(config, mode) {
    const sizes = (config && config.sizes) || {};
    switch (mode) {
    case "home":
        return sizes.homeHeight || 150;
    case "media":
        return sizes.mediaHeight || 230;
    case "message":
        return sizes.messageHeight || 120;
    case "summary":
        return sizes.summaryHeight || 160;
    case "notification":
        return sizes.notificationHeight || 110;
    default:
        return sizes.homeHeight || 150;
    }
}

function maxExpandedWidth(config) {
    const widths = [
        expandedWidthForMode(config, "home"),
        expandedWidthForMode(config, "media"),
        expandedWidthForMode(config, "message"),
        expandedWidthForMode(config, "summary"),
        expandedWidthForMode(config, "notification")
    ];
    return Math.max.apply(null, widths);
}

function maxExpandedHeight(config) {
    const heights = [
        expandedHeightForMode(config, "home"),
        expandedHeightForMode(config, "media"),
        expandedHeightForMode(config, "message"),
        expandedHeightForMode(config, "summary"),
        expandedHeightForMode(config, "notification")
    ];
    return Math.max.apply(null, heights);
}
