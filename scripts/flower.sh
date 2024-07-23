#!/bin/bash

echo -e "Configuring Flower"

# Node.js
apt-get update
apt-get -y install nodejs npm
npm install -g n
n stable
hash -r

npm install -g -f \
    webpack \
    webpack-cli \
    webpack-dev-server \
    serverless \
    yo \
    grunt-cli \
    gulp-cli \
    eas-cli \
    typescript \
    create-react-app \
    react-scripts \
    react-native-cli \
    next-cli \
    gatsby-cli \
    @angular/cli \
    @ionic/cli \
    @capacitor/cli \
    cordova \
    @nestjs/cli \
    yarn \
    jest-cli \
    ember-cli \
    git-lab-cli
    
npm install -g nodemon pm2

# VSC Code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
rm microsoft.gpg
apt-get update
apt-get -y install code

# Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get -y install google-chrome-stable

# Java
apt-get -y install \
    openjdk-8-jdk \
    openjdk-8-jre

# PHP
add-apt-repository -y ppa:ondrej/php
apt-get update
apt-get -y install php8.3-{apcu,bz2,cgi,cli,common,curl,dba,dev,fpm,gd,gearman,gmp,gnupg,http,igbinary,imagick,imap,interbase,intl,ldap,mbstring,mcrypt,memcache,memcached,mongodb,msgpack,mysql,oauth,opcache,pgsql,pspell,psr,raphf,readline,redis,smbclient,soap,solr,sqlite3,ssh2,sybase,tidy,uploadprogress,uuid,xdebug,xml,xmlrpc,xsl,yaml,zip}

# Package Tools
apt-get -y install \
    aptitude \
    flatpak \
    snap \
    snapd \
    python3-pip \
    php-pear

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Composer
wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php -- --quiet
mv composer.phar /usr/bin/composer

# Symfony CLI
wget https://get.symfony.com/cli/installer -O - | bash
mv "$HOME/.symfony5/bin/symfony" /usr/local/bin/symfony

# Drush
git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
cd /usr/local/src/drush
git checkout 8.x
ln -s /usr/local/src/drush/drush /usr/bin/drush
composer install --no-interaction

cd "$SCRIPT_DIR"

# Databases
apt-get -y install mysql-server-8.0 memcached redis redis-server

# Database GUI
add-apt-repository -y ppa:serge-rider/dbeaver-ce
apt-get update
apt-get -y install dbeaver-ce

# Ruby
apt-get -y install ruby rake gem

# Gradle
apt-get -y install gradle

# AWS
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --update

# Docker
apt-get update
apt-get install ca-certificates
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$TARGET_UBUNTU_VERSION") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Dart
git clone https://github.com/dart-lang/sdk.git /usr/local/src/dart-sdk
sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' 
sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' 
apt-get update
apt-get -y install dart

# Swift
apt-get -y install clang libpython3-all-dev
wget https://download.swift.org/swift-5.10.1-release/ubuntu2404/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu24.04.tar.gz
tar -xvf swift-5.10.1-RELEASE-ubuntu24.04.tar.gz
mv swift-5.10.1-RELEASE-ubuntu24.04 /usr/share/swift
rm swift-5.10.1-RELEASE-ubuntu24.04.tar.gz
echo "export PATH=/usr/share/swift/usr/bin:${PATH-/usr/bin}" >> "${HOME-/root}/.bashrc"
source "${HOME-/root}/.bashrc"

# Golang
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
sha256sum go1.16.7.linux-amd64.tar.gz
tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz
echo "export PATH=${PATH-/usr/bin}:/usr/local/go/bin" >> "${HOME-/root}/.bashrc"
source "${HOME-/root}/.bashrc"
rm go1.16.7.linux-amd64.tar.gz

# Rust
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y

# R
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
apt-get update
apt-get -y install r-base

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list
apt-get update
apt-get -y install spotify-client

# Various
apt-get -y install \
    gh \
    guake \
    kdeconnect \
    mpich