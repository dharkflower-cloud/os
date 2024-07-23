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

# Packages to be removed from the target system after installation completes succesfully
export TARGET_PACKAGE_REMOVE="
    ubiquity \
    casper \
    discover \
    laptop-detect \
    os-prober \
"

# Package customisation function. Update this function to customize packages
# present on the installed system.
function customize_image() {
    echo -e "Installing Cinnamon..."
    apt-get install -y \
        cinnamon \
        apt-utils >/dev/null

    # Set the bootloader logo
    cp /root/assets/ubuntu-logo.png /usr/share/plymouth/themes/ubuntu-logo/ubuntu-logo.png

    # Set the user and login screen backgrounds
    mkdir -p /usr/share/backgrounds
    cp /root/assets/solid-color-image.png /usr/share/backgrounds/user-background.png
    cp /root/assets/bg-large.png /usr/share/backgrounds/login-background.png

    # Configure backgrounds
    gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/user-background.png"
    gsettings set org.gnome.desktop.screensaver picture-uri "file:///usr/share/backgrounds/login-background.png"

    # Replace installation slideshow with static image
    cp /root/assets/Protoflower_beta3_large_whitebg.png /usr/share/ubiquity-slideshow/slides/slides.png

    # Create preseed file to skip location step
    echo "d-i time/zone string America/Denver" > /cdrom/preseed.cfg
    echo "d-i clock-setup/utc boolean true" >> /cdrom/preseed.cfg
    echo "d-i clock-setup/ntp boolean true" >> /cdrom/preseed.cfg

    echo -e "Installing useful tools..."
    apt-get install -y \
        clamav-daemon \
        terminator \
        apt-transport-https \
        curl \
        vim \
        nano \
        less >/dev/null

    echo -e "Purging unnecessary packages..."
    apt-get purge -y \
        gnome-mahjongg \
        gnome-mines \
        gnome-sudoku \
        aisleriot \
        hitori >/dev/null

    # Include flower.sh
    . /root/flower.sh
}
