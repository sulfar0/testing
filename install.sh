#!/bin/bash

hostname=shelver
username=test
password=topos
timezone=Asia/Jakarta
drivpath=/dev/sda
bootpath=/dev/sda1
procpath=/dev/sda2
swappath=/dev/sda3
homepath=/dev/sda4

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


# swap partition
function create_swap {
    mkswap $swappath &&
    swapon $swappath
}


# home partition
function create_home {
    yes | mkfs.ext4 $homepath &&
    mkdir -p /mnt/home &&
    mount $homepath /mnt/home
}


# package
function packages {
    pacstrap /mnt base base-devel neovim linux-lts linux linux-zen linux-firmware amd-ucode grub iwd mkinitcpio  --noconfirm &&
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
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch &&
    echo "GRUB_DISABLE_SUBMENU=y" >> /mnt/etc/default/grub
}


# mkinitcpio
function mkinitcpio {
    mkdir /mnt/boot/kernel &&
    mv /mnt/boot/vmlinuz* /mnt/boot/kernel &&
    mv /mnt/boot/amd-ucode /mnt/boot/kernel &&
    mkdir /mnt/etc/cmdline.d && 
    touch /mnt/etc/cmdline.d/{01-boot.conf,05-misc.conf} &&
    echo "root=$procpath" > /mnt/etc/cmdline.d/01-boot.conf &&
    echo "rw quiet" > /mnt/etc/cmdline.d/05-misc.conf &&
    echo "#linux zen preset" > /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo '#ALL_config="/etc/mkinitcpio.d/default.conf"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'ALL_kver="/boot/kernel/vmlinuz-linux-zen"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo "PRESETS=('default')" >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo '#default_uki="/boot/efi/EFI/linux/arch-linux-zen.efi"' >> /mnt/etc/mkinitcpio.d/linux-zen.preset &&
    echo 'MODULES=()' > /mnt/etc/mkinitcpio.conf &&
    echo 'BINARIES=()' >> /mnt/etc/mkinitcpio.conf &&
    echo 'FILES=()' >> /mnt/etc/mkinitcpio.conf &&
    echo 'HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)' >> /mnt/etc/mkinitcpio.conf &&
    arch-chroot /mnt mkinitcpio -P
}

# entries with initramfs
function entries {
cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "Arch-zen" {
    linux /kernel/vmlinuz-linux-zen root=$procpath rw
    initrd /kernel/amd-ucode.img
    initrd /initramfs-linux-zen.img 
}
menuentry "Arch-linux" {
    linux /kernel/vmlinuz-linux root=$procpath rw
    initrd /kernel/amd-ucode.img
    initrd /initramfs-linux.img 
}
menuentry "Arch-lts" {
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


    echo "configure root"
    create_proc
    clear &&
    sleep 5

  
    echo "configure boot"
    create_boot
    clear &&
    sleep 5


    echo "configure swap"
    create_swap
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





























