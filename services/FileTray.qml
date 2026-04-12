pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int maxEntries: 18
    property var entries: []

    readonly property bool hasEntries: entries.length > 0
    readonly property int count: entries.length

    function normalizeUrl(rawValue) {
        const text = String(rawValue === undefined || rawValue === null ? "" : rawValue).trim();
        if (text === "")
            return "";

        if (text.startsWith("file://"))
            return text;

        if (text.startsWith("/"))
            return "file://" + encodeURI(text);

        if (text.indexOf("://") !== -1)
            return text;

        return "";
    }

    function localPath(fileUrl) {
        const normalized = normalizeUrl(fileUrl);
        if (normalized === "")
            return "";

        const noScheme = normalized.startsWith("file://")
            ? normalized.substring(7)
            : normalized;

        try {
            return decodeURIComponent(noScheme);
        } catch (error) {
            return noScheme;
        }
    }

    function fileNameFromPath(filePath) {
        const normalized = String(filePath || "");
        const parts = normalized.split("/");
        return parts.length > 0 ? parts[parts.length - 1] : normalized;
    }

    function isImagePath(filePath) {
        const normalized = String(filePath || "").toLowerCase();
        return /\.(png|jpe?g|gif|webp|bmp|svg|avif|heic|heif)$/.test(normalized);
    }

    function entryForUrl(fileUrl) {
        const url = normalizeUrl(fileUrl);
        const path = localPath(url);
        const name = fileNameFromPath(path);
        return {
            url,
            path,
            name,
            isImage: isImagePath(path),
            addedAt: Date.now()
        };
    }

    function addUrls(urls) {
        if (!urls || urls.length === 0)
            return 0;

        const nextEntries = entries.slice();
        let addedCount = 0;

        for (let index = 0; index < urls.length; index++) {
            const entry = entryForUrl(urls[index]);
            if (entry.url === "")
                continue;

            const existingIndex = nextEntries.findIndex((existing) => existing.url === entry.url);
            if (existingIndex !== -1)
                nextEntries.splice(existingIndex, 1);
            else
                addedCount += 1;

            nextEntries.unshift(entry);
        }

        entries = nextEntries.slice(0, maxEntries);
        return addedCount;
    }

    function removeAt(index) {
        if (index < 0 || index >= entries.length)
            return;

        const nextEntries = entries.slice();
        nextEntries.splice(index, 1);
        entries = nextEntries;
    }

    function removeUrl(fileUrl) {
        const url = normalizeUrl(fileUrl);
        if (url === "")
            return;

        const targetPath = localPath(url);
        const normalizePath = value => String(value || "").replace(/\/+$/, "");
        const normalizedTargetPath = normalizePath(targetPath);

        const index = entries.findIndex(entry => {
            const entryUrl = normalizeUrl(entry && entry.url ? entry.url : "");
            if (entryUrl === url)
                return true;

            const entryPath = entry && entry.path ? String(entry.path) : localPath(entryUrl);
            if (normalizedTargetPath !== "" && normalizePath(entryPath) === normalizedTargetPath)
                return true;

            return false;
        });

        if (index !== -1)
            removeAt(index);
    }

    function clear() {
        entries = [];
    }
}
