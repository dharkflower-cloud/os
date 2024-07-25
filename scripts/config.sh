#!/bin/bash

# This script provides common customization options for the ISO

# The version of Ubuntu to generate. Successfully tested: bionic, cosmic, disco, eoan, focal, groovy, jammy
# See https://wiki.ubuntu.com/DevelopmentCodeNames for details
export TARGET_UBUNTU_VERSION="jammy"

# The Ubuntu Mirror URL. It's better to change for faster download.
# More mirrors see: https://launchpad.net/ubuntu/+archivemirrors
export TARGET_UBUNTU_MIRROR="http://us.archive.ubuntu.com/ubuntu/"

# The packaged version of the Linux kernel to install on target image.
# See https://wiki.ubuntu.com/Kernel/LTSEnablementStack for details
export TARGET_KERNEL_PACKAGE="linux-generic"

# The file (no extension) of the ISO containing the generated disk image,
# the volume id, and the hostname of the live environment are set from this name.
export TARGET_NAME="flower"

# The text label shown in GRUB for starting installation
export GRUB_INSTALL_LABEL="Install Flower Linux"

# Packages to be removed from the target system after installation completes successfully
export TARGET_PACKAGE_REMOVE="
    ubiquity
    casper
    discover
    laptop-detect
    os-prober
"

# Customization functions
function set_bootloader_logo() {
    mkdir -p /usr/share/plymouth/themes/ubuntu-logo
    cp $SCRIPT_DIR/assets/ubuntu-logo.png /usr/share/plymouth/themes/ubuntu-logo/ubuntu-logo.png
}

function set_backgrounds() {
    mkdir -p /usr/share/backgrounds

    gsettings set org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/user-background.png"
    gsettings set org.cinnamon.desktop.screensaver picture-uri "file:///usr/share/backgrounds/login-background.png"
}

function replace_slideshow() {
    mkdir -p /usr/share/ubiquity-slideshow/slides
    cp $SCRIPT_DIR/assets/solid-color-image.png /usr/share/ubiquity-slideshow/slides/slides.png
}

# Package customization function
function customize_image() {
    # Include flower.sh
    . $SCRIPT_DIR/flower.sh

    # Customization steps
    set_bootloader_logo
    set_backgrounds
    replace_slideshow
}
