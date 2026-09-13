#!/bin/bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "Do not run as root. The script uses sudo where needed."
    exit 1
fi

echo "Uninstalling nouveau HDMI wake fix"
echo

rm -f "$HOME/.local/bin/force-modeset.sh"
echo "Removed $HOME/.local/bin/force-modeset.sh"

sudo rm -f /usr/lib/systemd/system-sleep/force-modeset-resume.sh
echo "Removed /usr/lib/systemd/system-sleep/force-modeset-resume.sh"

if [ -f /etc/systemd/system/usb-wakeup.service ]; then
    sudo systemctl disable --now usb-wakeup.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/usb-wakeup.service
    sudo systemctl daemon-reload
    echo "Removed usb-wakeup.service"
fi

echo
echo "Scripts removed. gsettings values are unchanged."
echo "To restore default DPMS blanking:"
echo "  gsettings set org.gnome.desktop.session idle-delay 300"
echo "  gsettings set org.gnome.desktop.screensaver idle-activation-enabled true"
