# 8BitDo 2.4G dongle fix for Android (xpad)

A Magisk module for rooted Android devices where an **8BitDo controller on its 2.4 GHz USB dongle is detected but no button presses come through**. The same controller works over Bluetooth, and the same dongle works on Windows or desktop Linux.

## Symptoms

- The dongle enumerates and the kernel's `xpad` driver binds to it. `dmesg` shows something like `input: 8BitDo Ultimate 2C Wireless Controller`.
- Android lists the controller as a gamepad, and the dongle LED is solid (paired).
- Pressing buttons or moving the sticks does nothing. `getevent` stays silent, and the dongle's USB interrupt count in `/proc/interrupts` doesn't change.

## Cause

In XInput mode the 8BitDo dongle presents itself as an Xbox 360 controller and **sends no input reports until the host sends the Xbox 360 "set player LED" packet** (`01 03 06`).

Linux's `xpad` driver only sends that packet when it's built with `CONFIG_JOYSTICK_XPAD_LEDS=y`. Desktop distributions enable it, but some Android kernels don't, so the dongle waits forever. To check your kernel:

```sh
zcat /proc/config.gz | grep XPAD
# CONFIG_JOYSTICK_XPAD=y
# CONFIG_JOYSTICK_XPAD_LEDS is not set   <-- the problem
```

## What the module does

A small boot service watches for 8BitDo devices (USB vendor `2dc8`) bound to `xpad`. For each one it:

1. detaches `xpad` from the controller interface,
2. sends the LED packet to the interface's OUT endpoint through usbfs, using a tiny static helper (`src/xpad-led-kick.c`),
3. reattaches `xpad`.

From then on the dongle streams input normally, through the stock `xpad` driver, so Android sees a regular gamepad. The service repeats this whenever the dongle re-enumerates, for example when the controller powers on, wakes from sleep or reconnects. Each wake-up is logged to `/data/local/tmp/8bitdo-xpad-fix.log`.

No kernel rebuild or custom kernel module is needed.

## Install

1. Download `8bitdo-xpad-fix-v1.0.zip` from [Releases](../../releases).
2. Magisk app → Modules → Install from storage → pick the zip.
3. Reboot, turn the controller on in 2.4G mode, and check the log:
   ```sh
   su -c cat /data/local/tmp/8bitdo-xpad-fix.log
   # 2026-11-07 18:39:44 kicked 2dc8:310a at /dev/bus/usb/003/007 iface 00 ep 0x05: ok
   ```

Requires Magisk v20.4+ and an arm64 or 32-bit ARM device.

## Status

The method has been tested on a **Raspberry Pi 5 running KonstaKANG LineageOS 23.2 (Android 16, kernel 6.12, Magisk 31.1)** with an **8BitDo Ultimate 2C Wireless** (dongle `2dc8:310a`, idle ID `2dc8:301c`). It works at boot and after every controller power-cycle.

The packaged module in this repo (v1.0) has **not yet been installed on a device as a zip**. The same script and approach have been running there through Magisk's `service.d`. Reports from other devices and 8BitDo models are welcome.

## Optional: Xbox-style key layout

Without a key layout file for the controller, Android uses `Generic.kl`. That maps the right stick to RX/RY and the triggers to Z/RZ, which many games don't expect. `extras/Vendor_2dc8_Product_310a.kl` is Android's Xbox 360 layout (right stick = Z/RZ, triggers = LTRIGGER/RTRIGGER). To use it without modifying `/system`:

```sh
su -c 'mkdir -p /data/system/devices/keylayout && cp Vendor_2dc8_Product_310a.kl /data/system/devices/keylayout/ && chown -R system:system /data/system/devices && chmod 644 /data/system/devices/keylayout/*.kl && restorecon -R /data/system/devices'
```

Then reconnect the controller. **Note:** apps that saved their own button mapping under the generic layout, such as Kodi's controller config, need to be remapped afterwards. Rename the file to match your dongle's product ID if it's not `310a`.

## Build from source

```sh
NDK=/path/to/android-ndk ./build.sh    # -> dist/8bitdo-xpad-fix-<version>.zip
```

The helper takes `xpad-led-kick /dev/bus/usb/BBB/DDD <interface> <out-endpoint-hex>`, so it can be used on its own too.

## Uninstall

Remove the module in the Magisk app and reboot.

## License

MIT, see [LICENSE](LICENSE). `extras/Vendor_2dc8_Product_310a.kl` is derived from AOSP and keeps its Apache 2.0 header.
