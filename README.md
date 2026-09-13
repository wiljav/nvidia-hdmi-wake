# nouveau-hdmi-suspend-fix

Workaround for external HDMI monitors that fail to wake after suspend
or DPMS blanking on NVIDIA Turing GPUs using the nouveau driver on
Fedora 44 with GNOME 50 on Wayland.

Tested on Lenovo IdeaPad Gaming 81Y4 with a GeForce GTX 1650 Ti Mobile
and an AOC U34G2G1 ultrawide monitor connected over HDMI.

## Symptom

After resuming from suspend, or after the monitor enters DPMS power
save, the external HDMI monitor stays dark. The kernel reports the
connector as connected. `gdctl show` lists the monitor. Mutter believes
the output is active. The physical HDMI link is dead.

A full modeset — `Super+P`, or toggling display settings in GNOME —
restores the monitor, but only until the next power state transition.

## Cause

nouveau does not re-run HDMI link training after a power state
transition on Turing GPUs with GSP firmware. This is an upstream driver
defect. It is unrelated to the monitor, the cable, or the GPU hardware.

## Fix

A systemd sleep hook runs after resume, waits 4 seconds, and calls an
adaptive script that forces Mutter to reapply the display configuration.
This triggers nouveau to re-run HDMI link training. The monitor returns
within ~8 seconds of wake.

A second systemd service enables USB root hub wake, so an external
keyboard can wake the system with the laptop lid closed.

## Install

```sh
cd nouveau-hdmi-wake
./install.sh
```


Reboot once after installation.

## Uninstall
```sh
cd nouveau-hdmi-wake
./uninstall.sh
```

## Compatibility

- Fedora 44 with GNOME 50 on Wayland
- Kernel 7.1.13-200.fc44.x86_64
- nouveau driver (does not apply to the NVIDIA proprietary driver)
- Turing-generation NVIDIA GPU (GTX 16-series, RTX 20-series)
- HDMI monitor attached to the discrete GPU

## Not solved by this fix

- DPMS blanking is still broken in nouveau on this kernel.
  `idle-delay 0` disables DPMS entirely. Auto-suspend replaces it as
  the idle action.
- Replugging a USB keyboard during suspend does not wake the system.
- Kernel 7.2.4 has a separate cold-boot regression with nouveau.

## Why not use the NVIDIA proprietary driver

- Proprietary 580: cold boot requires an HDMI replug
- Proprietary 610: kernel oops during suspend entry

nouveau on kernel 7.1.13 has the fewest defects of the three.

## License

MIT

