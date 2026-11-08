// Send the Xbox 360 "player 1 LED" command to an interface's OUT endpoint.
// 8BitDo 2.4G dongles stay silent until they receive it, and kernels built
// without CONFIG_JOYSTICK_XPAD_LEDS never send it from the xpad driver.
// Usage: xpad-led-kick /dev/bus/usb/BBB/DDD <interface> <out-endpoint-hex>
#include <fcntl.h>
#include <linux/usbdevice_fs.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: %s /dev/bus/usb/BBB/DDD iface ep_out_hex\n", argv[0]);
        return 2;
    }
    unsigned int iface = strtoul(argv[2], NULL, 0);
    unsigned int ep = strtoul(argv[3], NULL, 16);
    unsigned char led[3] = {0x01, 0x03, 0x06};

    int fd = open(argv[1], O_RDWR);
    if (fd < 0) { perror("open"); return 1; }
    if (ioctl(fd, USBDEVFS_CLAIMINTERFACE, &iface) < 0) { perror("claim"); close(fd); return 1; }

    struct usbdevfs_bulktransfer xfer = { .ep = ep, .len = sizeof(led), .timeout = 1000, .data = led };
    int rc = ioctl(fd, USBDEVFS_BULK, &xfer);
    if (rc < 0) perror("send");

    ioctl(fd, USBDEVFS_RELEASEINTERFACE, &iface);
    close(fd);
    return rc < 0 ? 1 : 0;
}
