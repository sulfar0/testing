#!/bin/bash

hostname=shelver
username=testing-alpha
password=topos
timezone=Asia/Jakarta
drivpath=/dev/sda
bootpath=/dev/sda1
procpath=/dev/sda2
homepath=/dev/sda3
flashdisk=/dev/sdb


# boot partition
function create_boot {
    yes | mkfs.ext4 $bootpath &&
    mkdir -p /mnt/boot &&
    mount -o uid=0,gid=0,fmask=0077,dmask=0077 $bootpath /mnt  
}


function create_recovery {
    mount $flashdisk /opt &&
    mkdir /mnt {efi,loader,kernel} &&
    mkdir /mnt/efi {linux,boot,recovery,systemd} &&
    bootctl --path=/mnt install &&
    cp /opt/arch/boot/x86_64/* /mnt/efi/recovery &&
    cp -r /opt/arch/x86_64 /mnt/efi/recovery &&
    cat << EOF >> /mnt/loader/entries/recovery.conf
    title      recovery
    versions   archiso
    linux      /efi/recovery/vmlinuz-linux
    initrd     /efi/recovery/initramfs-linux.img
    options    archisobasedir=efi/recovery archisolabel=BOOT copytoram
    EOF
}


# root partition
function create_proc {
    yes | mkfs.ext4 $procpath &&
    mount $procpath /mnt
}


# home partition
function create_home {
    yes | mkfs.ext4 $homepath &&
    mkdir -p /mnt/home &&
    mount $homepath /mnt/home
}


# package
function packages {
    pacstrap /mnt base base-devel neovim linux-lts linux-firmware amd-ucode grub iwd --noconfirm &&
    genfstab -U /mnt >> /mnt/etc/fstab
}


# network
function network {
    cp /etc/systemd/network/* /mnt/etc/systemd/network &&
    mkdir -p /mnt/var/lib/iwd &&
    cp /var/lib/iwd/*.psk /mnt/var/lib/iwd
}


# hostname
function hostname {
    echo "$hostname" > /mnt/etc/hostname
}


# time
function gentime {
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /mnt/etc/localtime &&
    arch-chroot /mnt hwclock --systohc &&
    arch-chroot /mnt timedatectl set-ntp true &&
    arch-chroot /mnt timedatectl set-timezone $timezone &&
    arch-chroot /mnt timedatectl status &&
    arch-chroot /mnt timedatectl show-timesync --all
}


# locale
function locale {
    arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen &&
    arch-chroot /mnt locale-gen
}


# user
function user {
    arch-chroot /mnt useradd -m $username &&
    arch-chroot /mnt echo "$username:$password" | chpasswd &&
    echo "$username ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/nologin
}


# grub
function grub_install {
    arch-chroot /mnt grub-install --target=i386-pc /boot --bootloader-id=Arch &&
}


#cmdline
function cmdline {
    mkdir -p /mnt/etc/cmdline.d &&
    touch /mnt/etc/cmdline.d/{01-boot.conf,02-mods.conf,03-secs.conf,04-perf.conf,05-misc.conf} &&
    echo "root=UUID=$(blkid -s UUID -o value $procpath)" > /mnt/etc/cmdline.d/01-boot.conf
}


# mkinitcpio
function mkinitcpio {
    mkinitcpio -P
}


# mbr
function mbr-lts {
    echo "#linux lts preset" > /mnt/etc/mkinitcpio.d/linux-lts.preset &&
    echo 'ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-lts.preset &&
    echo 'ALL_kver="/boot/kernel/vmlinuz-linux-lts"' >> /mnt/etc/mkinitcpio.d/linux-lts.preset &&
    echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-lts.preset &&
    echo 'default_uki="/boot/efi/EFI/linux/arch-linux-lts.efi"' >> /mnt/etc/mkinitcpio.d/linux-lts.preset
}


# entries with initramfs
function entries {
cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "Shelver OS" {
    linux /kernel/vmlinuz-linux-lts root=$procpath rw
    initrd /kernel/amd-ucode.img
    initrd /initramfs-linux-lts.img 
}
EOF
}


# generate grub
function gen_grub {
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}


function runscript {
    
    echo "configure boot"
    create_boot
    clear &&
    sleep 5


    echo "configure boot"
    create_recovery
    clear &&
    sleep 5

    
    echo "configure root"
    create_proc
    clear &&
    sleep 5


    echo "configure home"
    create_home
    clear &&
    sleep 5
    

    echo "installing packages"
    packages
    clear &&
    sleep 5
    

    echo "configure network"
    network
    clear &&
    sleep 5


    echo "configure hostname"
    hostname
    clear &&
    sleep 5    


    echo "configure time"
    gentime
    clear &&
    sleep 5


    echo "configure locale"
    locale
    clear &&
    sleep 5


    echo "configure user"
    user
    clear &&
    sleep 5


    echo "generate grub"
    grub_install
    clear &&
    sleep 10


    echo "configure cmdline"
    cmdline
    clear &&
    sleep 10


    echo "configure mkinitcpio"
    mkinitcpio
    clear &&
    sleep 10


    echo "configure mbr"
    mbr-lts
    clear &&
    sleep 10


    echo "configure entries"
    entries
    clear &&
    sleep 10


    echo "configure grub boot"
    gen_grub
    clear &&
    sleep 10
}


runscript






























