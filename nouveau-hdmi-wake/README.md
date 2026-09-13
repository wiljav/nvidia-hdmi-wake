# nouveau HDMI wake fix

Workaround for external HDMI monitors that fail to wake after suspend
or hotplug on NVIDIA Turing GPUs using the nouveau driver.

## Problem

On some laptops with an external HDMI monitor wired to a Turing NVIDIA
GPU, the nouveau driver fails to re-run HDMI link training after a
power state transition or a hotplug event. The kernel reports the
connector as connected, Mutter reports the output as active, but the
physical HDMI link is dead and the monitor stays dark.

A full modeset restores the monitor. GNOME Settings achieves this by
applying a mirror config and then reverting it. This repository
reproduces those D-Bus calls directly.

Tested on:

- Laptop: Lenovo IdeaPad Gaming 81Y4
- GPU: NVIDIA TU117M (GeForce GTX 1650 Ti Mobile)
- Monitor: AOC U34G2G1, 3440x1440 via HDMI
- Kernel: 7.2.4-200.fc44.x86_64 (also works on 7.1.13)
- Driver: nouveau (kernel built-in)
- Distro: Fedora 44
- Desktop: GNOME 50 on Wayland

## How it works

Two D-Bus calls to org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig.

Lid open (two logical monitors):
  1. Apply a mirror config with HDMI-1 at 1920x1080 and eDP-1 at 1920x1080
  2. Wait 1 second
  3. Apply an extend config with HDMI-1 at 3440x1440 and eDP-1 at 1920x1080

Lid closed (one logical monitor):
  1. Apply HDMI-1 at 1920x1080
  2. Wait 1 second
  3. Apply HDMI-1 at 3440x1440

The resolution change forces Mutter to reprogram the CRTC, which
triggers nouveau to re-run HDMI link training. The monitor returns.

## Installation

    cd nouveau-hdmi-wake
    ./install.sh

Then reboot once.

## Configuration

Edit the top of force-modeset.sh if your monitor names, modes, or
layout differ. Verify current values with:

    gdctl show

## gsettings

The script does not change gsettings. For the fix to be useful you
should set:

    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800
    gsettings set org.gnome.desktop.session idle-delay 0

- `sleep-inactive-ac-type 'suspend'`: auto-suspend after idle
- `sleep-inactive-ac-timeout 1800`: after 30 minutes
- `idle-delay 0`: disable DPMS blanking, which is unfixable at userspace level

## What this fix does NOT solve

- DPMS blanking. The monitor will not recover from a DPMS-off state
  unless you run force-modeset.sh manually.
- USB keyboard wake requires the keyboard to be plugged in before
  suspend. Replugging during suspend does not wake the system.

## Do not add

- usb-wakeup.service: not needed, contains a toggle bug
- login-fix.sh or GDM dconf overrides: never verified
- Super+F12 keybinding for the script: does not work at the lock screen

## Uninstallation

    cd nouveau-hdmi-wake
    ./uninstall.sh

## References

- nouveau issue tracker: https://gitlab.freedesktop.org/drm/nouveau/-/issues
- Mutter DPMS bug: https://gitlab.gnome.org/GNOME/mutter/-/issues/4145
