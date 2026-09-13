#!/bin/bash
set -euo pipefail

echo "Applying gsettings values..."

gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800

echo
echo "Current values:"
gsettings get org.gnome.desktop.session idle-delay
gsettings get org.gnome.desktop.screensaver idle-activation-enabled
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout
