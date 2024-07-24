#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
#set -u                  # treat unset variable as error
#set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

CMD=(setup_host debootstrap run_chroot build_iso)

DATE=`TZ="UTC" date +"%y%m%d-%H%M%S"`

function find_index() {
    local ret;
    local i;
    for ((i=0; i<${#CMD[*]}; i++)); do
        if [ "${CMD[i]}" == "$1" ]; then
            index=$i;
            return;
        fi
    done
    echo "Command not found: $1"
    exit 1
}

function chroot_enter_setup() {
    sudo mount --bind /dev chroot/dev
    sudo mount --bind /run chroot/run
    sudo chroot chroot mount none -t proc /proc
    sudo chroot chroot mount none -t sysfs /sys
    sudo chroot chroot mount none -t devpts /dev/pts
}

function chroot_exit_teardown() {
    sudo chroot chroot umount /proc
    sudo chroot chroot umount /sys
    sudo chroot chroot umount /dev/pts
    sudo umount chroot/dev
    sudo umount chroot/run
}

# Load configuration values from file
function load_config() {
    . "$SCRIPT_DIR/config.sh"
}

function setup_host() {
    echo "=====> running setup_host ..."
    echo -e "Updating package list and installing necessary packages for the host..."
    sudo apt update >/dev/null
    sudo apt install -y \
        binutils \
        debootstrap \
        squashfs-tools \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        mtools \
        dosfstools \
        unzip >/dev/null
    sudo mkdir -p chroot
}

function debootstrap() {
    echo "=====> running debootstrap ... will take a couple of minutes ..."
    sudo debootstrap --arch=amd64 --variant=minbase $TARGET_UBUNTU_VERSION chroot $TARGET_UBUNTU_MIRROR
}

function run_chroot() {
    echo "=====> running run_chroot ..."

    chroot_enter_setup

    # Setup build scripts in chroot environment
    sudo ln -f $SCRIPT_DIR/chroot_build.sh chroot/root/chroot_build.sh
    sudo ln -f $SCRIPT_DIR/config.sh chroot/root/config.sh

    # Launch into chroot environment to build install image.
    sudo chroot chroot /usr/bin/env DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-readline} /root/chroot_build.sh -

    chroot_exit_teardown
}

function build_iso() {
    echo "=====> running build_iso ..."

    rm -rf image
    mkdir -p image/{casper,isolinux,install}

    # copy kernel files
    sudo cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
    sudo cp chroot/boot/initrd.img-**-**-generic image/casper/initrd

    # grub
    touch image/ubuntu
    cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=0

menuentry "${GRUB_INSTALL_LABEL}" {
   linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
   initrd /casper/initrd
}
EOF

    # Copy preseed file to ISO image
    sudo cp $SCRIPT_DIR/preseed.cfg image/preseed.cfg

    # generate manifest
    echo -e "Generating filesystem manifest..."
    sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest >/dev/null
    sudo
