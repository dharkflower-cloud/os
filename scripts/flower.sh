#!/bin/bash

echo -e "Installing Flower Applications"

# Node.js
echo "Installing Node.js and npm..."
apt-get update >/dev/null
apt-get -y install nodejs npm >/dev/null
npm install -g n >/dev/null
n stable >/dev/null
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
    git-lab-cli >/dev/null

npm install -g nodemon pm2 >/dev/null

# VSC Code
echo "Installing Visual Studio Code..."
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
rm microsoft.gpg
apt-get update >/dev/null
apt-get -y install code >/dev/null

# Chrome
echo "Installing Google Chrome..."
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - >/dev/null
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update >/dev/null
apt-get -y install google-chrome-stable >/dev/null

# Java
echo "Installing Java..."
apt-get -y install \
    openjdk-8-jdk \
    openjdk-8-jre >/dev/null

# PHP
echo "Installing PHP..."
add-apt-repository -y ppa:ondrej/php >/dev/null
apt-get update >/dev/null
apt-get -y install php8.3-{apcu,bz2,cgi,cli,common,curl,dba,dev,fpm,gd,gearman,gmp,gnupg,http,igbinary,imagick,imap,interbase,intl,ldap,mbstring,mcrypt,memcache,memcached,mongodb,msgpack,mysql,oauth,opcache,pgsql,pspell,psr,raphf,readline,redis,smbclient,soap,solr,sqlite3,ssh2,sybase,tidy,uploadprogress,uuid,xdebug,xml,xmlrpc,xsl,yaml,zip} >/dev/null

# Package Tools
echo "Installing package tools..."
apt-get -y install \
    aptitude \
    flatpak \
    snap \
    snapd \
    python3-pip \
    php-pear >/dev/null

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null

# Composer
echo "Installing Composer..."
wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php -- --quiet
mv composer.phar /usr/bin/composer >/dev/null

# Symfony CLI
echo "Installing Symfony CLI..."
wget https://get.symfony.com/cli/installer -O - | bash >/dev/null
mv "$HOME/.symfony5/bin/symfony" /usr/local/bin/symfony >/dev/null

# Drush
echo "Installing Drush..."
git clone https://github.com/drush-ops/drush.git /usr/local/src/drush >/dev/null
cd /usr/local/src/drush
git checkout 8.x >/dev/null
ln -s /usr/local/src/drush/drush /usr/bin/drush
composer install --no-interaction >/dev/null

cd "$SCRIPT_DIR"

# Databases
echo "Installing databases..."
apt-get -y install mysql-server-8.0 memcached redis redis-server >/dev/null

# Database GUI
echo "Installing database GUI..."
add-apt-repository -y ppa:serge-rider/dbeaver-ce >/dev/null
apt-get update >/dev/null
apt-get -y install dbeaver-ce >/dev/null

# Ruby
echo "Installing Ruby..."
apt-get -y install ruby rake gem >/dev/null

# Gradle
echo "Installing Gradle..."
apt-get -y install gradle >/dev/null

# AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" >/dev/null
unzip awscliv2.zip >/dev/null
./aws/install --update >/dev/null

# Docker
echo "Installing Docker..."
apt-get update >/dev/null
apt-get install ca-certificates >/dev/null
install -m 0755 -d /etc/apt/keyrings >/dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc >/dev/null
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$TARGET_UBUNTU_VERSION") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update >/dev/null
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null

# Dart
echo "Installing Dart..."
git clone https://github.com/dart-lang/sdk.git /usr/local/src/dart-sdk >/dev/null
sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' >/dev/null
sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' >/dev/null
apt-get update >/dev/null
apt-get -y install dart >/dev/null

# Swift
echo "Installing Swift..."
apt-get -y install clang libpython3-all-dev >/dev/null
wget https://download.swift.org/swift-5.10.1-release/ubuntu2404/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu24.04.tar.gz >/dev/null
tar -xvf swift-5.10.1-RELEASE-ubuntu24.04.tar.gz >/dev/null
mv swift-5.10.1-RELEASE-ubuntu24.04 /usr/share/swift >/dev/null
rm swift-5.10.1-RELEASE-ubuntu24.04.tar.gz
echo "export PATH=/usr/share/swift/usr/bin:${PATH-/usr/bin}" >> "${HOME-/root}/.bashrc"
source "${HOME-/root}/.bashrc"

# Golang
echo "Installing Golang..."
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz >/dev/null
sha256sum go1.16.7.linux-amd64.tar.gz >/dev/null
tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz >/dev/null
echo "export PATH=${PATH-/usr/bin}:/usr/local/go/bin" >> "${HOME-/root}/.bashrc"
source "${HOME-/root}/.bashrc"
rm go1.16.7.linux-amd64.tar.gz

# Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y >/dev/null

# R
echo "Installing R..."
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 >/dev/null
apt-get update >/dev/null
apt-get -y install r-base >/dev/null

# Spotify
echo "Installing Spotify..."
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg >/dev/null
echo "deb http://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list >/dev/null
apt-get update >/dev/null
apt-get -y install spotify-client >/dev/null

# Various
echo "Installing various utilities..."
apt-get -y install \
    gh \
    guake \
    kdeconnect \
    mpich >/dev/null
