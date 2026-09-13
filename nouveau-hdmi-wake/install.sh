#!/bin/bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "Do not run as root. The script uses sudo where needed."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="$USER"
USER_HOME="$HOME"

echo "Installing nouveau HDMI wake fix for user $USER_NAME"
echo

mkdir -p "$USER_HOME/.local/bin"
cp "$SCRIPT_DIR/force-modeset.sh" "$USER_HOME/.local/bin/force-modeset.sh"
chmod +x "$USER_HOME/.local/bin/force-modeset.sh"
echo "Installed $USER_HOME/.local/bin/force-modeset.sh"

sudo cp "$SCRIPT_DIR/force-modeset-resume.sh" /usr/lib/systemd/system-sleep/force-modeset-resume.sh
sudo chmod +x /usr/lib/systemd/system-sleep/force-modeset-resume.sh

echo "Installed /usr/lib/systemd/system-sleep/force-modeset-resume.sh"


bash "$SCRIPT_DIR/configure-gsettings.sh"

echo
echo "Installation complete. Reboot to apply."
