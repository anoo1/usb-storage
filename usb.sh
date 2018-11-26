#!/bin/sh

if [ $# -ne 2 ]
then
    echo "usage: $0 <start|stop> <config>" >&2
    exit 1
fi

action=$1
config=$2

gadget_name=mass-storage
gadget_dir=/sys/kernel/config/usb_gadget/$gadget_name

case "$config" in
0)
    nbd_device=/dev/nbd0
    ;;
*)
    echo "invalid config $config" >&2
    exit 1
    ;;
esac

set -ex

case "$action" in
start)
    mkdir -p $gadget_dir
    (
        cd $gadget_dir
    echo "0x1d6b" > idVendor
    echo "0x0199" > idProduct
    mkdir -p strings/0x409
    echo "0123456789" > strings/0x409/serialnumber
    echo "OpenBMC Inc." > strings/0x409/manufacturer
    echo "Virtual Media Device" > strings/0x409/product
    mkdir -p configs/c.1
    mkdir -p configs/c.1/strings/0x409
    echo "config 1" > configs/c.1/strings/0x409/configuration
    mkdir -p functions/mass_storage.usb0
    ln -s functions/mass_storage.usb0 configs/c.1
    mkdir -p functions/mass_storage.usb0/lun.0
    echo 1 >functions/mass_storage.usb0/lun.0/removable
    echo 1 >functions/mass_storage.usb0/lun.0/ro
    echo 0 >functions/mass_storage.usb0/lun.0/cdrom
    echo $nbd_device >functions/mass_storage.usb0/lun.0/file
    echo "1e6a0000.usb-vhub:p4" >UDC
    )
    ;;
stop)
    (
        cd $gadget_dir
    rm configs/c.1/mass_storage.usb0
    rmdir functions/mass_storage.usb0
    rmdir configs/c.1/strings/0x409
    rmdir configs/c.1
    rmdir strings/0x409
    )
    rmdir $gadget_dir
    ;;
*)
    echo "invalid action $action" >&2
    exit 1
esac

exit 0

