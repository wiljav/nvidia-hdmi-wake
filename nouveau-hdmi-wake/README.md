# nouveau HDMI wake fix

Workaround for external HDMI monitors that fail to wake after suspend
or DPMS blanking on NVIDIA Turing GPUs using the nouveau driver.

## Problem

On some laptops with an external HDMI monitor wired to a Turing NVIDIA
GPU, the nouveau driver fails to re-run HDMI link training after a
power state transition. The kernel reports the connector as connected,
Mutter reports the output as active, but the physical HDMI link is dead
and the monitor stays dark.

Cold boot works. Suspend entry and exit complete cleanly. Only the
HDMI link is not re-established.

Confirmed on:

- Laptop: Lenovo IdeaPad Gaming 81Y4
- GPU: NVIDIA TU117M (GeForce GTX 1650 Ti Mobile)
- Monitor: AOC U34G2G1, 3440x1440 via HDMI
- Kernel: 7.1.13-200.fc44.x86_64
- Driver: nouveau (kernel built-in, GSP firmware)
- Distro: Fedora 44
- Desktop: GNOME 50 on Wayland

## Symptoms

- After suspend/resume, monitor stays dark
- After DPMS blank, monitor stays dark
- A full modeset (Super+P, or GNOME Settings display toggle) restores it
- card*-HDMI-A-1/status reads connected
- gdctl show lists the monitor
- The monitor briefly detects a signal then goes back to sleep

## What this fix does

A systemd sleep hook runs after resume from suspend, waits 4 seconds,
and calls a user-level script that forces Mutter to reapply the display
configuration. This triggers nouveau to re-run HDMI link training. The
monitor comes back within ~8 seconds of wake.

The script is adaptive:

- Lid open (two logical monitors): disables HDMI, then restores both
- Lid closed (one logical monitor): swaps HDMI to an alternate refresh
  rate, then swaps back

The mode swap forces a modeset without requiring a second monitor.

A separate systemd service enables USB root hub wake so an external
keyboard can wake the system from suspend with the lid closed.

## Requirements

- Fedora 44 or a similar distro with GNOME 50 on Wayland and systemd 258+
- nouveau driver (not the NVIDIA proprietary driver)
- An HDMI monitor attached to the NVIDIA GPU
- gdctl (part of gnome-control-center on Fedora 44)
- A working external keyboard or other wake device

## Installation

    cd nouveau-hdmi-wake
    ./install.sh

Then reboot once.

## Manual installation

1. Copy force-modeset.sh to ~/.local/bin/ and mark executable
2. Copy force-modeset-resume.sh to /usr/lib/systemd/system-sleep/
   and mark executable.
3. Copy usb-wakeup.service to /etc/systemd/system/ and enable it.
   Edit the USB paths if your keyboard is not on usb1 / 1-3.
4. Run configure-gsettings.sh
5. Reboot

## Configuration

The script assumes:

- HDMI connector: HDMI-1
- Main mode: 3440x1440@59.973
- Alternate mode (single-monitor case): 3440x1440@99.982
- Internal panel: eDP-1, mode 1920x1080@60.164
- Layout: HDMI at (0, 0), internal at (3440, 360)

If your setup differs, edit the variables at the top of
force-modeset.sh. Verify mode strings with gdctl show.

## What this fix does NOT solve

- DPMS wake is still broken in nouveau on this kernel.
  idle-delay 0 disables DPMS blanking entirely. Auto-suspend replaces
  it as the idle action.
- Replugging a USB keyboard during suspend does not wake the system.
  The keyboard must be plugged in before suspend.
- Cold boot on kernel 7.2.4 fails with the same driver defect.
  Kernel 7.1.13 is the tested baseline.

## Why not use the NVIDIA proprietary driver

- Proprietary 580: no HDMI wake issue, but cold boot requires an HDMI replug
- Proprietary 610: kernel oops during suspend entry
  (nvEvoDisableVblankSemControl), requires hard power-off

Nouveau on kernel 7.1.13 has the fewest issues of the three, so this
fix works around its remaining defect.

## Uninstallation

    cd nouveau-hdmi-wake
    ./uninstall.sh

## References

- nouveau issue tracker: https://gitlab.freedesktop.org/drm/nouveau/-/issues
- Mutter DPMS bug: https://gitlab.gnome.org/GNOME/mutter/-/issues/4145
