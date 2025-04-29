#!/bin/bash
set -e

clear

# Warna
red() { echo -e "\\033[31;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    wait $pid
}

# Deteksi OS
detect_os() {
    if [[ -e /etc/debian_version ]]; then
        source /etc/os-release
        OS=$ID
    else
        red "Unsupported OS. Only Debian/Ubuntu are supported."
        exit 1
    fi
}

# Update system
update_system() {
    yellow "Updating system..."
    (apt update -y && apt dist-upgrade -y) & spinner
}

# Remove unnecessary packages
remove_unwanted() {
    yellow "Removing unwanted packages..."
    (apt-get remove --purge -y ufw firewalld exim4 || true) & spinner
}

# Install dependencies
install_packages() {
    yellow "Installing packages..."
    (
    apt install -y sudo screen curl jq bzip2 gzip coreutils rsyslog iftop \
    htop zip unzip net-tools sed gnupg gnupg1 bc apt-transport-https \
    build-essential dirmngr libxml-parser-perl neofetch screenfetch git lsof \
    openssl openvpn easy-rsa fail2ban tmux stunnel4 vnstat squid \
    dropbear libsqlite3-dev socat cron bash-completion ntpdate xz-utils \
    gnupg2 dnsutils lsb-release chrony
    ) & spinner
}

# Install Node.js
install_nodejs() {
    yellow "Installing Node.js..."
    (curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs) & spinner
}

# Setup vnstat
setup_vnstat() {
    yellow "Setting up vnstat 2.6..."
    (
    systemctl restart vnstat || true
    cd /root
    wget -q https://humdi.net/vnstat/vnstat-2.6.tar.gz
    tar zxvf vnstat-2.6.tar.gz
    cd vnstat-2.6
    ./configure --prefix=/usr --sysconfdir=/etc
    make
    make install
    cd
    rm -f /root/vnstat-2.6.tar.gz
    rm -rf /root/vnstat-2.6

    NET=$(ip -o -4 route show to default | awk '{print $5}')
    [ -z "$NET" ] && NET="eth0"

    sed -i "s/Interface \"eth0\"/Interface \"$NET\"/g" /etc/vnstat.conf
    chown vnstat:vnstat /var/lib/vnstat -R
    systemctl enable vnstat
    systemctl restart vnstat
    ) & spinner
}

# Install VPN tools
install_vpn_tools() {
    yellow "Installing VPN related packages..."
    (
    apt install -y libnss3-dev libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev \
    libcap-ng-utils libselinux1-dev libcurl4-nss-dev flex bison make libnss3-tools \
    libevent-dev xl2tpd pptpd
    ) & spinner
}

# Main Execution
main() {
    detect_os
    update_system
    remove_unwanted
    install_packages
    install_nodejs
    setup_vnstat
    install_vpn_tools

    green "✅ All dependencies successfully installed!"
    sleep 2
    clear
}

main
