#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
#set -u                  # treat unset variable as error
#set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

CMD=(setup_host install_pkg finish_up)

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

function setup_host() {
    echo "=====> running setup_host ..."

   cat <<EOF > /etc/apt/sources.list
deb $TARGET_UBUNTU_MIRROR $TARGET_UBUNTU_VERSION main restricted universe multiverse
deb-src $TARGET_UBUNTU_MIRROR $TARGET_UBUNTU_VERSION main restricted universe multiverse

deb $TARGET_UBUNTU_MIRROR $TARGET_UBUNTU_VERSION-security main restricted universe multiverse
deb-src $TARGET_UBUNTU_MIRROR $TARGET_UBUNTU_VERSION-security main restricted universe multiverse

deb $TARGET_UBUNTU_MIRROR $TARGET_UBUNTU_VERSION-updates main restricted universe multiverse
deb-src $TARGET_UBUNTU_MIRROR $TARGET_UBUNTU_VERSION-updates main restricted universe multiverse
EOF

    echo "$TARGET_NAME" > /etc/hostname

    # we need to install systemd first, to configure machine id
    echo "Updating package list and installing systemd-sysv..."
    apt-get update >/dev/null
    apt-get install -y \
        libterm-readline-gnu-perl \
        systemd-sysv \
        apt-utils >/dev/null

    #configure machine id
    dbus-uuidgen > /etc/machine-id
    ln -fs /etc/machine-id /var/lib/dbus/machine-id

    # don't understand why, but multiple sources indicate this
    dpkg-divert --local --rename --add /sbin/initctl
    ln -s /bin/true /sbin/initctl
}

# Load configuration values from file
function load_config() {
    . "$SCRIPT_DIR/config.sh"
}

function install_pkg() {
    echo "=====> running install_pkg ... will take a long time ..."

    # Attempting to fix session start bug
    apt-get update >/dev/null
    apt-get install -y lightdm apt-utils
    dpkg-reconfigure lightdm

    echo "Installing software-properties-common and upgrading packages..."
    apt-get install -y software-properties-common >/dev/null
    apt-get -y upgrade >/dev/null

    # Add Cinnamon PPA and install Cinnamon
    echo "Adding Cinnamon PPA and installing Cinnamon..."
    add-apt-repository -y ppa:ubuntucinnamonremix/all
    apt-get update >/dev/null
    apt-get install -y ubuntucinnamon-environment

    # Remove GNOME and Unity
    echo "Removing GNOME and Unity..."
    apt-get remove -y \
        ubuntu-gnome-desktop \
        ubuntu-gnome-wallpapers >/dev/null

    # install live packages
    echo "Installing core packages..."
    apt-get install -y \
        sudo \
        ubuntu-standard \
        casper \
        discover \
        laptop-detect \
        os-prober \
        network-manager \
        resolvconf \
        net-tools \
        wireless-tools \
        wpagui \
        grub-common \
        grub-gfxpayload-lists \
        grub-pc \
        grub-pc-bin \
        grub2-common \
        locales >/dev/null
    
    # install kernel
    echo "Installing kernel package..."
    apt-get install -y --no-install-recommends \
        $TARGET_KERNEL_PACKAGE >/dev/null

    # graphic installer - ubiquity
    echo "Installing Ubiquity installer..."
    apt-get install -y \
        ubiquity \
        ubiquity-casper \
        ubiquity-frontend-gtk \
        ubiquity-ubuntu-artwork >/dev/null

    # Call into config function
    customize_image

    # remove unused and clean up apt cache
    echo "Removing unused packages and cleaning up apt cache..."
    apt-get autoremove -y >/dev/null

    # final touch
    dpkg-reconfigure locales >/dev/null
    dpkg-reconfigure resolvconf >/dev/null

    # network manager
    cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF

    dpkg-reconfigure network-manager >/dev/null

    apt-get clean -y >/dev/null
}

function finish_up() { 
    echo "=====> finish_up"

    # truncate machine id (why??)
    truncate -s 0 /etc/machine-id

    # remove diversion (why??)
    rm /sbin/initctl
    dpkg-divert --rename --remove /sbin/initctl

    # Remove specific files and directories instead of patterns
    rm -rf /tmp/*
    rm -f ~/.bash_history
}

# =============   main  ================

load_config

# check number of args
if [[ $# == 0 || $# > 3 ]]; then echo "Usage: $0 [start_cmd] [-] [end_cmd]"; exit 1; fi

# loop through args
dash_flag=false
start_index=0
end_index=${#CMD[*]}
for ii in "$@";
do
    if [[ $ii == "-" ]]; then
        dash_flag=true
        continue
    fi
    find_index $ii
    if [[ $dash_flag == false ]]; then
        start_index=$index
    else
        end_index=$(($index+1))
    fi
done
if [[ $dash_flag == false ]]; then
    end_index=$(($start_index + 1))
fi

# loop through the commands
for ((ii=$start_index; ii<$end_index; ii++)); do
    ${CMD[ii]}
done

echo "$0 - Initial build is done!"
