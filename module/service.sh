#!/system/bin/sh
# Wake 8BitDo 2.4G dongles bound to the kernel xpad driver.
# The dongle stays silent until it receives the Xbox 360 "set player LED" packet. Kernels built
# without CONFIG_JOYSTICK_XPAD_LEDS never send it, so the pad is detected but no input arrives.
# For each new dongle: detach xpad, send the packet over usbfs, reattach xpad. Re-runs whenever the
# dongle re-enumerates (controller power-cycle, sleep/wake, replug).
MODDIR=${0%/*}
LOG=/data/local/tmp/8bitdo-xpad-fix.log
DRV=/sys/bus/usb/drivers/xpad
VENDORS="2dc8"

case "$(getprop ro.product.cpu.abi)" in
  arm64*) KICK=$MODDIR/bin/arm64-v8a/xpad-led-kick ;;
  armeabi*) KICK=$MODDIR/bin/armeabi-v7a/xpad-led-kick ;;
  *) echo "$(date '+%F %T') unsupported ABI $(getprop ro.product.cpu.abi)" >> $LOG; exit 0 ;;
esac

log() { echo "$(date '+%F %T') $*" >> $LOG; }

if [ ! -d "$DRV" ]; then
  log "xpad driver not present in this kernel; nothing to do"
  exit 0
fi

done_list=""
while true; do
  for path in $DRV/*:*; do
    [ -e "$path" ] || continue
    iface=${path##*/}
    dev=${iface%:*}
    sys=/sys/bus/usb/devices/$dev
    vid=$(cat $sys/idVendor 2>/dev/null)
    case " $VENDORS " in *" $vid "*) ;; *) continue ;; esac
    key="$dev:$(cat $sys/devnum)"
    case " $done_list " in *" $key "*) continue ;; esac

    ifnum=$(cat $sys/$iface/bInterfaceNumber)
    ep=""
    for e in $sys/$iface/ep_*; do
      [ "$(cat $e/direction 2>/dev/null)" = "out" ] && ep=$(cat $e/bEndpointAddress) && break
    done
    node=$(printf "/dev/bus/usb/%03d/%03d" "$(cat $sys/busnum)" "$(cat $sys/devnum)")

    echo "$iface" > $DRV/unbind
    if [ -n "$ep" ] && $KICK "$node" "$ifnum" "$ep" 2>>$LOG; then r=ok; else r=failed; fi
    echo "$iface" > $DRV/bind
    log "kicked $vid:$(cat $sys/idProduct) at $node iface $ifnum ep 0x$ep: $r"
    done_list="$done_list $key"
  done
  sleep 2
done
