.pragma library

function moduleEnabled(modules, mode) {
    return !!(modules && modules[mode]);
}

function firstEnabledMode(modules) {
    const order = ["home", "media", "message", "summary", "notification"];
    for (let i = 0; i < order.length; i++) {
        if (moduleEnabled(modules, order[i])) {
            return order[i];
        }
    }
    return "home";
}

function sanitizeMode(modules, fallbackMode, mode) {
    if (moduleEnabled(modules, mode)) {
        return mode;
    }
    if (moduleEnabled(modules, fallbackMode)) {
        return fallbackMode;
    }
    return firstEnabledMode(modules);
}

function resolveExpandedMode(ctx) {
    const modules = ctx.modules || {};

    if (ctx.pinned && moduleEnabled(modules, ctx.pinnedMode)) {
        return ctx.pinnedMode;
    }

    if (ctx.hasUrgentNotification && moduleEnabled(modules, "notification")) {
        return "notification";
    }

    if (ctx.hasMessageLikeNotification && moduleEnabled(modules, "message")) {
        return "message";
    }

    if (ctx.mediaAvailable && moduleEnabled(modules, "media")) {
        return "media";
    }

    if (moduleEnabled(modules, ctx.defaultMode)) {
        return ctx.defaultMode;
    }

    if (moduleEnabled(modules, "summary")) {
        return "summary";
    }

    return firstEnabledMode(modules);
}
