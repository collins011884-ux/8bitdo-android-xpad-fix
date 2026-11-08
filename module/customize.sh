SKIPUNZIP=0

case "$ARCH" in
  arm64|arm) ;;
  *) abort "! Unsupported architecture: $ARCH (only arm64 and arm are included)" ;;
esac

if [ ! -d /sys/bus/usb/drivers/xpad ]; then
  ui_print "! Warning: this kernel has no xpad driver loaded."
  ui_print "! This module only helps when xpad is present but the pad sends no input."
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/bin/arm64-v8a/xpad-led-kick" 0 0 0755
set_perm "$MODPATH/bin/armeabi-v7a/xpad-led-kick" 0 0 0755
