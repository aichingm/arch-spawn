#!/usr/bin/zsh

# check for clean drive

if [[ ! 0 -eq $(grep -c 'sda[0-9]' /proc/partitions) ]]; then echo "/dev/sda has a partition table, aborting!";exit;fi

fdisk /dev/sda <<EOF
o
n
p
1


w

EOF

mkfs.ext4 /dev/sda1

mount /dev/sda1 /mnt

if [[ "1" -eq $(bash pro.sh profile Offline) ]]; then 
    mkdir -p /mnt/var/lib/pacman/sync
    mkdir -p /mnt/var/cache/pacman/pkg
    cp /var/lib/pacman/sync/* /mnt/var/lib/pacman/sync/
    cp /var/cache/pacman/pkg/* /mnt/var/cache/pacman/pkg/
fi

pacstrap /mnt $(cat /root/pkgs)

genfstab -U /mnt >> /mnt/etc/fstab

cp /root/chroot.sh /mnt/root/chroot.sh
cp /root/pro.sh /mnt/root/pro.sh
mkdir /mnt/root/profiles
cp /root/pro.sh /mnt/root/pro.sh
cp /root/profiles/* /mnt/root/profiles/

arch-chroot /mnt <<EOC
bash /root/chroot.sh
EOC

reboot
