#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DATE=$(TZ="UTC" date +"%y%m%d-%H%M%S")

CMD=(setup_host debootstrap run_chroot build_iso)

function find_index() {
    for i in "${!CMD[@]}"; do
        if [ "${CMD[$i]}" == "$1" ]; then
            index=$i
            return
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
    echo "Updating package list and installing necessary packages for the host..."
    sudo apt update -y >/dev/null
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

function verify_assets_directory() {
    if [ ! -d "$SCRIPT_DIR/assets" ]; then
        echo "Assets directory not found in $SCRIPT_DIR"
        exit 1
    fi

    echo "=====> Verifying assets directory and files in $SCRIPT_DIR ..."
    for file in "$SCRIPT_DIR/assets"/*; do
        if [ ! -f "$file" ]; then
            echo "Missing file: $file"
            exit 1
        fi
    done
    echo "All asset files are present."
}

function copy_to_chroot() {
    echo "=====> Copying files to chroot environment ..."

    # Ensure chroot/root directory exists
    if [ ! -d chroot/root ]; then
        sudo mkdir -p chroot/root
    fi

    # Ensure chroot/root/assets directory exists
    if [ ! -d chroot/root/assets ]; then
        sudo mkdir -p chroot/root/assets
    fi

    echo "Copying assets directory to chroot environment..."
    sudo cp -r "$SCRIPT_DIR/assets"/* "chroot/root/assets/"

    # Verify files are copied
    for file in "$SCRIPT_DIR/assets"/*; do
        if [ ! -f "chroot/root/assets/$(basename "$file")" ]; then
            echo "File missing after copy: $(basename "$file")"
            exit 1
        fi
    done
    echo "All files copied successfully."
}

function run_chroot() {
    echo "=====> running run_chroot ..."

    chroot_enter_setup
    copy_to_chroot

    # Setup build scripts in chroot environment
    sudo cp "$SCRIPT_DIR/chroot_build.sh" "chroot/root/chroot_build.sh"
    sudo cp "$SCRIPT_DIR/config.sh" "chroot/root/config.sh"
    sudo cp "$SCRIPT_DIR/flower.sh" "chroot/root/flower.sh"

    # Launch into chroot environment to build install image.
    sudo chroot chroot /usr/bin/env DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-readline} /root/chroot_build.sh -

    chroot_exit_teardown
}

function build_iso() {
    echo "=====> running build_iso ..."

    rm -rf image
    mkdir -p image/{casper,isolinux,install}

    sudo cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
    sudo cp chroot/boot/initrd.img-**-**-generic image/casper/initrd

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

    sudo cp "$SCRIPT_DIR/preseed.cfg" "image/preseed.cfg"

    echo "Generating filesystem manifest..."
    sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest >/dev/null
    sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
    for pkg in $TARGET_PACKAGE_REMOVE; do
        sudo sed -i "/$pkg/d" image/casper/filesystem.manifest-desktop
    done

    echo "Compressing root filesystem..."
    sudo mksquashfs chroot image/casper/filesystem.squashfs -noappend -no-duplicates -no-recovery -wildcards -e "var/cache/apt/archives/*" -e "tmp/*" -e "tmp/.*" -e "swapfile" >/dev/null
    printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

    cat <<EOF > image/README.diskdefines
#define DISKNAME  ${GRUB_INSTALL_LABEL}
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

    echo "Creating ISO image..."
    pushd "$SCRIPT_DIR/image"
    grub-mkstandalone --format=x86_64-efi --output=isolinux/bootx64.efi --locales="" --fonts="" "boot/grub/grub.cfg=isolinux/grub.cfg" >/dev/null

    (
        cd isolinux
        dd if=/dev/zero of=efiboot.img bs=1M count=10
        sudo mkfs.vfat efiboot.img >/dev/null
        LC_CTYPE=C mmd -i efiboot.img efi efi/boot
        LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
    )

    grub-mkstandalone --format=i386-pc --output=isolinux/core.img --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" --modules="linux16 linux normal iso9660 biosdisk search" --locales="" --fonts="" "boot/grub/grub.cfg=isolinux/grub.cfg" >/dev/null

    cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img

    sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'bios.img' -e 'efiboot.img' > md5sum.txt)" >/dev/null

    sudo xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "$TARGET_NAME" -eltorito-boot boot/grub/bios.img -no-emul-boot -boot-load-size 1 -boot-info-table --eltorito-catalog boot/grub/boot.cat --grub2-boot-info --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot -append_partition 2 0xef isolinux/efiboot.img -output "$SCRIPT_DIR/$TARGET_NAME.iso" -m "isolinux/efiboot.img" -m "isolinux/bios.img" -graft-points "/EFI/efiboot.img=isolinux/efiboot.img" "/boot/grub/bios.img=isolinux/bios.img" "." >/dev/null

    popd
}

# Main Execution Flow
cd "$SCRIPT_DIR"
load_config

verify_assets_directory

if [[ $# == 0 || $# > 3 ]]; then echo "Usage: $0 [start_cmd] [-] [end_cmd]"; exit 1; fi

dash_flag=false
start_index=0
end_index=${#CMD[@]}
for arg in "$@"; do
    if [[ $arg == "-" ]]; then
        dash_flag=true
        continue
    fi
    find_index $arg
    if [[ $dash_flag == false ]]; then
        start_index=$index
    else
        end_index=$((index + 1))
    fi
done
if [[ $dash_flag == false ]]; then
    end_index=$((start_index + 1))
fi

for ((i=$start_index; i<$end_index; i++)); do
    ${CMD[i]}
done

echo "$0 - Initial build is done!"
