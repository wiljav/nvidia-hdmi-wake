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


echo
echo "Scripts removed. gsettings values are unchanged."
echo "To restore default DPMS blanking:"
echo "  gsettings set org.gnome.desktop.session idle-delay 300"
