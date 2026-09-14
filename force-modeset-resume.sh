#!/bin/bash
case "$1" in
  post)
    SESSION=$(loginctl list-sessions --no-legend | awk '$4 == "seat0" && $6 == "user" {print $1; exit}')
    if [ -z "$SESSION" ]; then
        exit 0
    fi

    UID_NUM=$(loginctl show-session "$SESSION" -p User --value)
    USER_HOME=$(getent passwd "$UID_NUM" | cut -d: -f6)

    if [ -z "$UID_NUM" ] || [ -z "$USER_HOME" ]; then
        exit 0
    fi

    systemd-run --on-active=10 \
        --unit="force-modeset-resume-$(date +%s)" \
        --uid="$UID_NUM" \
        --gid="$UID_NUM" \
        --setenv=XDG_RUNTIME_DIR=/run/user/"$UID_NUM" \
        --setenv=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$UID_NUM"/bus \
        /bin/bash "$USER_HOME/.local/bin/force-modeset.sh" 1
    ;;
esac
