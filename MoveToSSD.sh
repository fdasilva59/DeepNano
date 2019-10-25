#/bin/bash

#------------------------------------------------------------------------------
# Script to setup the Jetson Nano in order to boot from a USB drive 
#
# Instructions :
#    - Connect a USB drive (make sure it is the only one USB storage attached to  
#    the Jetson Nano). All information on the USB drive will be lost (format)
#    
#    - Execute the script
#
# MIT License
#
# Copyright acknowledgements:
# https://github.com/JetsonHacksNano/rootOnUSB
# https://www.jetsonhacks.com/2019/04/25/jetson-nano-run-on-usb-drive/
#
#------------------------------------------------------------------------------
set -e

DEVICE_PATH='/dev/sda1'

#-------------------------
#       Cleaning
#------------------------- 
sudo rm -rf /tmp/.[!.]* /tmp/*

#-------------------------
# Adding USB to initramfs
#------------------------- 
printf "\n#--------------------------\n# Adding USB to initramfs \n#--------------------------\n"
cat > /tmp/usb-firmware <<- "EOF"
if [ "$1" = "prereqs" ]; then exit 0; fi
. /usr/share/initramfs-tools/hook-functions
copy_file firmware /lib/firmware/tegra21x_xusb_firmware
EOF

sudo mv /tmp/usb-firmware /etc/initramfs-tools/hooks
cd /etc/initramfs-tools/hooks
sudo chown root:root /etc/initramfs-tools/hooks/usb-firmware
sudo chmod +x /etc/initramfs-tools/hooks/usb-firmware
sudo mkinitramfs -o /boot/initrd-xusb.img

#-------------------------
#   Formating USB Drive
#------------------------- 
printf "\n#--------------------------\n#  Formating USB Drive \n#--------------------------\n"
lsblk --fs

echo "Device Path: "$DEVICE_PATH
if grep -qs 'JetsonNanoSSD' /proc/mounts ; then
    echo "Unmounting /media/$USER/JetsonNanoSSD"
    sudo umount -f /media/$USER/JetsonNanoSSD
    if [ -e /media/$USER/JetsonNanoSSD ] ; then
        sudo rm -f /media/$USER/JetsonNanoSSD
    fi
else
echo "/media/$USER/JetsonNanoSSD is not mounted: Ok to continue"
fi

sudo mkfs.ext4 -L JetsonNanoSSD $DEVICE_PATH  
sudo mkdir -p /media/$USER/JetsonNanoSSD
sudo chown -R fab:fab /media/$USER/JetsonNanoSSD
sudo mount  /dev/sda1 /media/$USER/JetsonNanoSSD


#-------------------------
#  Copy FS on USB Drive
#------------------------- 
printf "\n#--------------------------\n#  Copy FS on USB Drive \n#--------------------------\n"

DESTINATION_TARGET=$(findmnt -rno TARGET "$DEVICE_PATH")
echo "Destination Target: "$DESTINATION_TARGET

if [ "$DESTINATION_TARGET" = "" ] ; then
    echo "Unable to find the mount point of: ""$DEVICE_PATH"
    exit 1
fi

sudo rsync -axHAWX --numeric-ids --info=progress2 --exclude=/proc / "$DESTINATION_TARGET"


#-------------------------
#   Backup Boot config
#------------------------- 
printf "\n#--------------------------\n#   Backup Boot config \n#--------------------------\n"
#if [ ! -e /boot/Image.backup ]; then
#    sudo cp /boot/Image /boot/Image.backup
#fi

if [ ! -e /boot/extlinux/extlinux.conf.backup ]; then
    echo "Backing up boot config"
    sudo cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.bck
fi

#-------------------------
#   Update Boot config
#------------------------- 
printf "\n#--------------------------\n#   Update Boot config \n#--------------------------\n"

cat > /tmp/extlinux.conf <<- "EOF"
TIMEOUT 30
DEFAULT primary

MENU TITLE L4T boot options

LABEL primary
      MENU LABEL primary kernel
      LINUX /boot/Image
      INITRD /boot/initrd-xusb.img
      APPEND ${cbootargs} root=/dev/sda1 rootwait rootfstype=ext4

LABEL backup
      MENU LABEL primary kernel
      LINUX /boot/Image
      INITRD /boot/initrd
      APPEND ${cbootargs} quiet

# When testing a custom kernel, it is recommended that you create a backup of
# the original kernel and add a new entry to this file so that the device can
# fallback to the original kernel. To do this:
#
# 1, Make a backup of the original kernel
#      sudo cp /boot/Image /boot/Image.backup
#
# 2, Copy your custom kernel into /boot/Image
#
# 3, Uncomment below menu setting lines for the original kernel
#
# 4, Reboot

# LABEL backup
#    MENU LABEL backup kernel
#    LINUX /boot/Image.backup
#    INITRD /boot/initrd
#    APPEND ${cbootargs} quiet

EOF

sudo mv /tmp/extlinux.conf /boot/extlinux/extlinux.conf

#-------------------------
#       Cleaning
#------------------------- 
sudo rm -rf /tmp/.[!.]* /tmp/*


#-------------------------
#        Reboot
#------------------------- 
printf "\n#--------------------------\n# System to reboot in 5 sec \n#--------------------------\n"
#sleep 5
#sudo shutdown -r now
