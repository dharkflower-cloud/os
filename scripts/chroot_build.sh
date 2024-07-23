#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
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
    apt-get update
    apt-get install -y libterm-readline-gnu-perl systemd-sysv

    #configure machine id
    dbus-uuidgen > /etc/machine-id
    ln -fs /etc/machine-id /var/lib/dbus/machine-id

    # don't understand why, but multiple sources indicate this
    dpkg-divert --local --rename --add /sbin/initctl
    ln -s /bin/true /sbin/initctl
}

# Load configuration values from file
function load_config() {
    if [[ -f "$SCRIPT_DIR/config.sh" ]]; then 
        . "$SCRIPT_DIR/config.sh"
    else
        >&2 echo "Unable to find config file $SCRIPT_DIR/config.sh, aborting."
        exit 1
    fi
}


function install_pkg() {
    echo "=====> running install_pkg ... will take a long time ..."
    apt-get -y upgrade

    # Add Cinnamon PPA and install Cinnamon
    add-apt-repository -y ppa:embrosyn/cinnamon
    apt-get update
    apt-get install -y cinnamon

    # Remove GNOME and Unity
    apt-get remove -y ubuntu-gnome-desktop ubuntu-gnome-wallpapers

    # install live packages
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
    locales
    
    case $TARGET_UBUNTU_VERSION in
        "focal" | "bionic")
            apt-get install -y lupin-casper
            ;;
        *)
            echo "Package lupin-casper is not needed. Skipping."
            ;;
    esac
    
    # install kernel
    apt-get install -y --no-install-recommends $TARGET_KERNEL_PACKAGE

    # graphic installer - ubiquity
    apt-get install -y \
    ubiquity \
    ubiquity-casper \
    ubiquity-frontend-gtk \
    ubiquity-slideshow-ubuntu \
    ubiquity-ubuntu-artwork

    # Call into config function
    customize_image

    # remove unused and clean up apt cache
    apt-get autoremove -y

    # final touch
    dpkg-reconfigure locales
    dpkg-reconfigure resolvconf

    # network manager
    cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF

    dpkg-reconfigure network-manager

    apt-get clean -y
}

function finish_up() { 
    echo "=====> finish_up"

    # truncate machine id (why??)
    truncate -s 0 /etc/machine-id

    # remove diversion (why??)
    rm /sbin/initctl
    dpkg-divert --rename --remove /sbin/initctl

    rm -rf /tmp/* ~/.bash_history /root/* /root/.*  # Ensure /root cleanup
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
