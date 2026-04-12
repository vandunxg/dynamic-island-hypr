#!/usr/bin/env bash

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

resolve_bin() {
    if command -v quickshell >/dev/null 2>&1; then
        command -v quickshell
        return
    fi

    if command -v qs >/dev/null 2>&1; then
        command -v qs
        return
    fi

    return 1
}

resolve_config() {
    if [[ -n "${DYNAMIC_ISLAND_CONFIG_PATH:-}" && -f "${DYNAMIC_ISLAND_CONFIG_PATH}" ]]; then
        printf '%s\n' "${DYNAMIC_ISLAND_CONFIG_PATH}"
        return
    fi

    local candidates=(
        "${CONFIG_HOME}/quickshell/dynamic-island-standalone/shell.qml"
        "${CONFIG_HOME}/quickshell/ii/shell.dynamic-island.qml"
        "${CONFIG_HOME}/quickshell/default/shell.dynamic-island.qml"
    )

    local item
    for item in "${candidates[@]}"; do
        if [[ -f "${item}" ]]; then
            printf '%s\n' "${item}"
            return
        fi
    done

    return 1
}

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    for candidate in wayland-1 wayland-0; do
        if [[ -S "${RUNTIME_DIR}/${candidate}" ]]; then
            export WAYLAND_DISPLAY="${candidate}"
            break
        fi
    done
fi

BIN="$(resolve_bin || true)"
if [[ -z "${BIN}" ]]; then
    echo "dynamic-island-standalone: quickshell binary not found" >&2
    exit 127
fi

CONFIG_PATH="$(resolve_config || true)"
if [[ -z "${CONFIG_PATH}" ]]; then
    echo "dynamic-island-standalone: no shell config found" >&2
    exit 1
fi

exec "${BIN}" -p "${CONFIG_PATH}"
