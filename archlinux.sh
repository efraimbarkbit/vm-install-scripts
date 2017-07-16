parted -s /dev/sda mktable msdos
parted -s /dev/sda mkpart primary 0% 100m
parted -s /dev/sda mkpart primary 100m 100%

mkfs.ext2 /dev/sda1
mkfs.btrfs /dev/sda2

mkdir /mnt/boot
mount /dev/sda2 /mnt
mount /dev/sda1 /mnt/boot

echo "Server = https://ftp.acc.umu.se/mirror/archlinux/\$repo/os/\$arch\nServer = https://archlinux.dynamict.se/\$repo/os/\$arch\nServer = https://ftp.lysator.liu.se/pub/archlinux/\$repo/os/\$arch\nServer = https://ftp.myrveln.se/pub/linux/archlinux/\$repo/os/\$arch\nServer = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
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

mv /boot/syslinux/syslinux.cfg.new /boot/syslinux/syslinux.cfg
systemctl enable systemd-networkd
echo root:root | chpasswd

EOF

umount /mnt/{boot,}
