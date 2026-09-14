# nvidia-hdmi-wake

Fix for external HDMI monitors that fail to wake after suspend or
hotplug on NVIDIA GPUs on Fedora 44 with GNOME 50 on Wayland.

Tested on Lenovo IdeaPad Gaming 81Y4 with a GeForce GTX 1650 Ti Mobile
(Turing) and an AOC U34G2G1 ultrawide monitor connected over HDMI.

## Problem

On hybrid laptops with the external HDMI port wired to the discrete
NVIDIA GPU, the display driver may fail to re-run HDMI link training
after a power state transition or a hotplug event. The kernel reports
the connector as connected. Mutter reports the output as active. The
physical HDMI link is dead and the monitor stays dark.

A full modeset restores the monitor. In GNOME Settings this is done by
applying a mirror config and then reverting it. This repository
reproduces those D-Bus calls directly.

## How it works

A systemd sleep hook runs after resume from suspend and calls
force-modeset.sh, which issues two D-Bus calls to
org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig.

Lid open (two logical monitors):
  1. Apply a mirror config with HDMI-1 at 1920x1080 and eDP-1 at 1920x1080
  2. Wait 1 second
  3. Apply an extend config with HDMI-1 at 3440x1440 and eDP-1 at 1920x1080

Lid closed (one logical monitor):
  1. Apply HDMI-1 at 1920x1080
  2. Wait 1 second
  3. Apply HDMI-1 at 3440x1440

The resolution change forces Mutter to reprogram the CRTC, which
triggers the driver to re-run HDMI link training.

The hook uses systemd-run with --on-active=10. NVIDIA's resume path is
slower than nouveau's. At shorter delays the D-Bus calls are accepted
but have no effect.

## Installation

    cd ~/Documents/Linux-scripts
    ./install.sh

Then reboot once.

## Configuration

Edit the top of force-modeset.sh if your monitor names, modes, or
layout differ. Verify current values with:

    gdctl show

## gsettings

    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800
    gsettings set org.gnome.desktop.session idle-delay 0

- sleep-inactive-ac-type 'suspend': auto-suspend after idle
- sleep-inactive-ac-timeout 1800: after 30 minutes
- idle-delay 0: disable DPMS blanking, which is unfixable at userspace level

## Driver configuration

Two driver paths work with this fix.

### NVIDIA proprietary (current configuration)

Tested on kernel 7.2.5 with driver 610.57.04.

1. Remove any existing NVIDIA packages:

       sudo dnf remove '*nvidia*' -x nvidia-gpu-firmware

2. Install the proprietary akmod:

       sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda

3. Force the proprietary kernel module. RPM Fusion defaults to the
   open module on Turing:

       sudo sh -c 'echo "%_without_kmod_nvidia_detect 1" > /etc/rpm/macros.nvidia-kmod'

4. Rebuild the kernel module:

       sudo akmods --force --rebuild

5. Verify the proprietary module is loaded:

       modinfo -l nvidia
       # Expected: NVIDIA

6. Disable GSP firmware. Required on Turing. The open kernel module
   cannot disable GSP and exhibits scroll lag. The proprietary module
   allows disabling it:

       sudo tee /etc/modprobe.d/nvidia-gsp-off.conf >/dev/null <<'INNEREOF'
       options nvidia NVreg_EnableGpuFirmware=0
       INNEREOF

7. Mask nvidia-powerd. It exits immediately on this hardware because
   the SBIOS does not expose the NVPCF interface:

       sudo systemctl mask nvidia-powerd.service

8. Rebuild initramfs:

       sudo dracut --force

9. Reboot.

### nouveau

Tested on kernels 7.1.13, 7.2.4, and 7.2.5.

The nouveau driver ships with the kernel. Install the scripts, set the
gsettings values above, and reboot.

Trade-offs compared to the proprietary module:

- No CUDA, no NVENC, lower 3D performance
- No scroll lag (nouveau does not use GSP)
- No GSP suspend issues

## What was tried and did not work

Removed during development:

- usb-wakeup.service: contained a toggle bug in the XHC enable logic.
  Not needed; udev enables keyboard wake from suspend automatically.
- login-fix.sh and its autostart entry: never verified to change
  anything.
- GDM dconf drop-in to disable greeter auto-suspend: the GDM user has
  a separate dconf profile and the drop-in did not take effect.
- Super+F12 keybinding for force-modeset.sh: works only in a user
  session, not at the lock screen or greeter.
- nouveau.runpm=0 kernel argument: caused cold-boot failure on
  kernel 7.2.4.
- nouveau.config=NvGspRm=0: wrong parameter.
- nvidia_drm.fbdev=0: mixed results across systems. Not the cause of
  any observed problem here.

## Limitations

- DPMS blanking. The monitor will not recover from a DPMS-off state.
  idle-delay 0 disables it entirely. Auto-suspend replaces it as the
  idle action.
- Replugging a USB keyboard during suspend does not wake the system.
  The keyboard must be plugged in before suspend.
- The resolution change in force-modeset.sh briefly interrupts display
  output. The monitor flickers through the alternate mode.

## Uninstallation

    cd ~/Documents/Linux-scripts
    ./uninstall.sh

To restore DPMS blanking:

    gsettings set org.gnome.desktop.session idle-delay 300

## References

- nouveau issue tracker: https://gitlab.freedesktop.org/drm/nouveau/-/issues
- Mutter DPMS bug: https://gitlab.gnome.org/GNOME/mutter/-/issues/4145

## License

MIT
