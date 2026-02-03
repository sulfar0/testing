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


# root partition
function create_proc {
    yes | mkfs.ext4 $procpath &&
    mount $procpath /mnt
}


# boot partition
function create_boot {
    yes | mkfs.ext4 $bootpath &&
    mkdir -p /mnt/boot &&
    mount $bootpath /mnt/boot
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
    arch-chroot /mnt grub-install --target=i386-pc $drivpath
}


# mkinitcpio
function mkinitcpio {
    arch-chroot /mnt mkinitcpio -P
}


# generate grub
function gen_grub {
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}


function runscript {


    echo "configure root"
    create_proc
    clear &&
    sleep 5

  
    echo "configure boot"
    create_boot
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
    

    echo "configure mkinitcpio"
    mkinitcpio
    clear &&
    sleep 10


    echo "configure grub boot"
    gen_grub
    clear &&
    sleep 10
}


runscript





























