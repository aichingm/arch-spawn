#!/bin/bash

$(bash /root/pro.sh profile )

ln -sf /usr/share/zoneinfo/$(bash /root/pro.sh profile Zone)/$(bash /root/pro.sh profile SubZone) /etc/localtime

hwclock --systohc

echo "$(bash /root/pro.sh profile Locale) UTF-8" >> /etc/locale.gen

locale-gen

echo "LANG=$(bash /root/pro.sh profile Locale)" > /etc/locale.conf

echo $(bash /root/pro.sh profile Hostname) > /etc/hostname
echo "127.0.0.1 $(bash /root/pro.sh profile Hostname).localdomain $(bash /root/pro.sh profile Hostname)" >> /etc/hosts

mkinitcpio -p linux

passwd <<EOF
$(bash /root/pro.sh profile Password)
$(bash /root/pro.sh profile Password)
EOF

syslinux-install_update -i -m -a

sed -i '54s:.*:   APPEND root=/dev/sda1 rw:g' /boot/syslinux/syslinux.cfg
sed -i '60s:.*:   APPEND root=/dev/sda1 rw:g' /boot/syslinux/syslinux.cfg

if [ -f /root/after_install.sh ]; then
    bash  /root/after_install.sh
fi

exit
