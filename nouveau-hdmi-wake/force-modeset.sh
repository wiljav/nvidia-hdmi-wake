#!/bin/bash
# force-modeset.sh
# Forces Mutter to re-apply display config, re-running HDMI link training.
# Workaround for nouveau HDMI wake failure after suspend/DPMS.

set -euo pipefail
WAIT="${1:-1}"

BUS="org.gnome.Mutter.DisplayConfig"
OBJ="/org/gnome/Mutter/DisplayConfig"
IFACE="org.gnome.Mutter.DisplayConfig"

HDMI_MAIN_MODE="3440x1440@59.973"
HDMI_ALT_MODE="1920x1080@60.000"
EDP_MODE="1920x1080@60.164"

get_serial() {
    gdbus call --session --dest "$BUS" --object-path "$OBJ" \
        --method "$IFACE.GetCurrentState" \
        | grep -oP '^\(uint32 \K[0-9]+'
}

has_edp_active() {
    gdbus call --session --dest "$BUS" --object-path "$OBJ" \
        --method "$IFACE.GetCurrentState" \
        | grep -q '"eDP-1"'
}

apply() {
    local cfg="$1"
    local serial
    serial=$(get_serial)
    gdbus call --session --dest "$BUS" --object-path "$OBJ" \
        --method "$IFACE.ApplyMonitorsConfig" \
        "$serial" 1 "$cfg" "{}" >/dev/null
}

if has_edp_active; then
    echo "Lid open: mirror then extend"
    ALT="[(0, 0, 1.0, 0, true, [(\"HDMI-1\", \"$HDMI_ALT_MODE\", {}), (\"eDP-1\", \"$EDP_MODE\", {})])]"
    MAIN="[(0, 0, 1.0, 0, true, [(\"HDMI-1\", \"$HDMI_MAIN_MODE\", {})]), (3440, 360, 1.0, 0, false, [(\"eDP-1\", \"$EDP_MODE\", {})])]"
else
    echo "Lid closed: HDMI resolution swap"
    ALT="[(0, 0, 1.0, 0, true, [(\"HDMI-1\", \"$HDMI_ALT_MODE\", {})])]"
    MAIN="[(0, 0, 1.0, 0, true, [(\"HDMI-1\", \"$HDMI_MAIN_MODE\", {})])]"
fi

apply "$ALT"
sleep "$WAIT"
apply "$MAIN"
echo "Done."
