#!/usr/bin/bash
# force-modeset.sh
# Forces Mutter to re-apply display config, re-running HDMI link training.
# Workaround for nouveau DPMS/resume link-training failure.
#
# Two paths:
#   - Two logical monitors (lid open): disable HDMI, then restore both.
#   - One logical monitor  (lid closed): swap HDMI to alternate mode, then back.

set -euo pipefail

WAIT="${1:-1}"

HDMI_MAIN="3440x1440@59.973"
HDMI_ALT="3440x1440@99.982"
EDP_MODE="1920x1080@60.164"

COUNT=$(gdctl show 2>/dev/null | grep -c '^├──Logical monitor\|^└──Logical monitor')

if [ "$COUNT" -ge 2 ]; then
    echo "Two monitors detected. Disable HDMI, then restore."
    gdctl set --layout-mode logical \
        --logical-monitor --monitor eDP-1 --mode "$EDP_MODE" --x 0 --y 0 --primary
    sleep "$WAIT"
    gdctl set --layout-mode logical \
        --logical-monitor --monitor HDMI-1 --mode "$HDMI_MAIN" --x 0 --y 0 --primary \
        --logical-monitor --monitor eDP-1 --mode "$EDP_MODE" --x 3440 --y 360
else
    echo "Single monitor detected. Swap HDMI mode, then restore."
    gdctl set --logical-monitor --monitor HDMI-1 --mode "$HDMI_ALT" --x 0 --y 0 --primary
    sleep "$WAIT"
    gdctl set --logical-monitor --monitor HDMI-1 --mode "$HDMI_MAIN" --x 0 --y 0 --primary
fi

echo "Done."
