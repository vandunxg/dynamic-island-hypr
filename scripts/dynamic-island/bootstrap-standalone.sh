#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
QS_CONFIG_ROOT="${CONFIG_HOME}/quickshell"

TARGET_NAME="dynamic-island-standalone"
TARGET_DIR=""
RUN_NOW=1
ENABLE_AUTOSTART=0

print_help() {
    cat <<'EOF'
Dynamic Island Standalone bootstrapper

Usage:
  bootstrap-standalone.sh [options]

Options:
  --config-name <name>   Target quickshell config name (default: dynamic-island-standalone)
  --target-dir <path>    Absolute target directory (overrides --config-name)
  --autostart            Append exec-once line to ~/.config/hypr/hyprland.conf
  --no-run               Install only, do not launch quickshell now
  -h, --help             Show this help

Examples:
  ./bootstrap-standalone.sh
  ./bootstrap-standalone.sh --autostart
  ./bootstrap-standalone.sh --config-name my-dynamic-island
  ./bootstrap-standalone.sh --target-dir "$HOME/.config/quickshell/my-di"
EOF
}

while (($# > 0)); do
    case "$1" in
        --config-name)
            TARGET_NAME="${2:-}"
            shift 2
            ;;
        --target-dir)
            TARGET_DIR="${2:-}"
            shift 2
            ;;
        --autostart)
            ENABLE_AUTOSTART=1
            shift
            ;;
        --no-run)
            RUN_NOW=0
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            print_help
            exit 1
            ;;
    esac
done

if [[ -z "${TARGET_DIR}" ]]; then
    TARGET_DIR="${QS_CONFIG_ROOT}/${TARGET_NAME}"
fi

mkdir -p "${QS_CONFIG_ROOT}"

echo "[1/5] Installing standalone config to: ${TARGET_DIR}"
if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
        --exclude='.git/' \
        --exclude='*.log' \
        "${SOURCE_ROOT}/" "${TARGET_DIR}/"
else
    rm -rf "${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"
    cp -a "${SOURCE_ROOT}/." "${TARGET_DIR}/"
fi

cp "${SOURCE_ROOT}/shell.dynamic-island.qml" "${TARGET_DIR}/shell.qml"

echo "[2/5] Ensuring Dynamic Island config keys"
mkdir -p "${CONFIG_HOME}/illogical-impulse"
CONFIG_JSON="${CONFIG_HOME}/illogical-impulse/config.json"
if [[ ! -f "${CONFIG_JSON}" ]]; then
    printf '{}\n' > "${CONFIG_JSON}"
fi

python3 - "${CONFIG_JSON}" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        data = {}
except Exception:
    data = {}

bar = data.setdefault("bar", {})
di = bar.setdefault("dynamicIsland", {})
di["enabled"] = True
di.setdefault("preset", "hyprlandPort")
di.setdefault("preferredMonitor", "active")
di.setdefault("protrusionPx", 3)

path.write_text(json.dumps(data, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
PY

if (( ENABLE_AUTOSTART == 1 )); then
    echo "[3/5] Configuring Hyprland autostart"
    HYPR_CONF="${HOME}/.config/hypr/hyprland.conf"
    mkdir -p "$(dirname -- "${HYPR_CONF}")"
    if [[ ! -f "${HYPR_CONF}" ]]; then
        touch "${HYPR_CONF}"
    fi

    RUN_LINE="exec-once = quickshell -p ${TARGET_DIR}/shell.qml"
    if ! grep -Fq "${RUN_LINE}" "${HYPR_CONF}"; then
        {
            echo
            echo "# Dynamic Island Standalone"
            echo "${RUN_LINE}"
        } >> "${HYPR_CONF}"
        echo "  Added autostart line to ${HYPR_CONF}"
    else
        echo "  Autostart line already exists"
    fi
else
    echo "[3/5] Skipping Hyprland autostart (use --autostart to enable)"
fi

echo "[4/5] Validating entrypoint"
if [[ ! -f "${TARGET_DIR}/shell.qml" ]]; then
    echo "Install failed: ${TARGET_DIR}/shell.qml not found" >&2
    exit 1
fi

if (( RUN_NOW == 1 )); then
    echo "[5/5] Launching Dynamic Island standalone now"
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        echo "  No WAYLAND_DISPLAY detected. Skipping launch."
        echo "  Run manually: quickshell -p ${TARGET_DIR}/shell.qml"
        exit 0
    fi

    quickshell kill -p "${TARGET_DIR}" >/dev/null 2>&1 || true
    quickshell -p "${TARGET_DIR}/shell.qml" --daemonize
    echo "  Started."
else
    echo "[5/5] Install complete (launch skipped by --no-run)"
    echo "  Run manually: quickshell -p ${TARGET_DIR}/shell.qml"
fi
