parted -s /dev/sda mktable msdos
parted -s /dev/sda mkpart primary 0% 100m
parted -s /dev/sda mkpart primary 100m 100%

mkfs.ext2 -F /dev/sda1
mkfs.btrfs /dev/sda2

mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
rankmirrors -n 3 /etc/pacman.d/mirrorlist.orig >/etc/pacman.d/mirrorlist
pacman -Syy

pacstrap /mnt base base-devel
arch-chroot /mnt pacman -S syslinux --noconfirm

cp /etc/pacman.d/mirrorlist* /mnt/etc/pacman.d
genfstab -p /mnt >>/mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
echo "archlinux" >/etc/hostname

ln -s /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
locale >/etc/locale.conf

echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
echo "en_US ISO-8859-1" >>/etc/locale.gen

locale-gen
mkinitcpio -p linux
syslinux-install_update -iam

sed 's/root=.*/root=\/dev\/sda2 ro/' < /boot/syslinux/syslinux.cfg > /boot/syslinux/syslinux.cfg.new
cp /boot/syslinux/syslinux.cfg.new /boot/syslinux/syslinux.cfg

echo root:root | chpasswd

systemctl enable systemd-networkd
systemctl enable dhcpcd

pacman --noconfirm -S xorg-server xorg-xinit virtualbox-guest-utils virtualbox-guest-modules-arch firefox
modprobe vboxvideo

xinit

printf "#!/bin/sh\nmatchbox-window-manager -use_titlebar no &\nexec firefox" > ~/.xinitrc

localectl set-keymap sv-latin1
localectl set-x11-keymap fi microsoftprose

EOF

umount /mnt/{boot,}
reboot
