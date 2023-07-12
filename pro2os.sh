#!/bin/bash

# This script will do the following to install RustDesk Server Opensource replacing RustDesk Server Pro
# 1. Disable and removes the services
# 2. Download and extract RustDesk OS Services to the above folder
# 3. Create systemd services for hbbs and hbbr and start them with OS arguments

# Get Username
uname=$(whoami)

sudo systemctl stop rustdesk-hbbs.service
sudo systemctl stop rustdesk-hbbr.service
sudo systemctl disable rustdesk-hbbs.service
sudo systemctl disable rustdesk-hbbr.service
sudo rm /etc/systemd/system/rustdesk-hbbs.service
sudo rm /etc/systemd/system/rustdesk-hbbr.service


ARCH=$(uname -m)


# identify OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID

    UPSTREAM_ID=${ID_LIKE,,}

    # Fallback to ID_LIKE if ID was not 'ubuntu' or 'debian'
    if [ "${UPSTREAM_ID}" != "debian" ] && [ "${UPSTREAM_ID}" != "ubuntu" ]; then
        UPSTREAM_ID="$(echo ${ID_LIKE,,} | sed s/\"//g | cut -d' ' -f1)"
    fi


elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS=SuSE
    VER=$(cat /etc/SuSe-release)
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
    VER=$(cat /etc/redhat-release)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi


# output ebugging info if $DEBUG set
if [ "$DEBUG" = "true" ]; then
    echo "OS: $OS"
    echo "VER: $VER"
    echo "UPSTREAM_ID: $UPSTREAM_ID"
    exit 0
fi

cd /var/lib/rustdesk-server/

#Download latest version of Rustdesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')

echo "Installing Rustdesk Server"
if [ "${ARCH}" = "x86_64" ] ; then
wget https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-amd64.zip
unzip rustdesk-server-linux-amd64.zip
mv amd64/static /var/lib/rustdesk-server/
sudo mv amd64/hbbr /usr/bin/
sudo mv amd64/hbbs /usr/bin/
rm -rf amd64/
rm -rf rustdesk-server-linux-amd64.zip
elif [ "${ARCH}" = "armv7l" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-armv7.zip"
unzip rustdesk-server-linux-armv7.zip
mv armv7/static /var/lib/rustdesk-server/
sudo mv armv7/hbbr /usr/bin/
sudo mv armv7/hbbs /usr/bin/
rm -rf armv7/
rm -rf rustdesk-server-linux-armv7.zip
elif [ "${ARCH}" = "aarch64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-arm64v8.zip"
unzip rustdesk-server-linux-arm64v8.zip
mv arm64v8/static /var/lib/rustdesk-server/
sudo mv arm64v8/hbbr /usr/bin/
sudo mv arm64v8/hbbs /usr/bin/
rm -rf arm64v8/
rm -rf rustdesk-server-linux-arm64v8.zip
fi

sudo chmod +x /usr/bin/hbbs
sudo chmod +x /usr/bin/hbbr


# Setup Systemd to launch hbbs
rustdeskhbbs="$(cat << EOF
[Unit]
Description=Rustdesk Signal Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/usr/bin/hbbs -k _
WorkingDirectory=/var/lib/rustdesk-server/
User=${uname}
Group=${uname}
Restart=always
StandardOutput=append:/var/log/rustdesk-server/hbbs.log
StandardError=append:/var/log/rustdesk-server/hbbs.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdeskhbbs}" | sudo tee /etc/systemd/system/rustdesk-hbbs.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable rustdesk-hbbs.service
sudo systemctl start rustdesk-hbbs.service

# Setup Systemd to launch hbbr
rustdeskhbbr="$(cat << EOF
[Unit]
Description=Rustdesk Relay Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/usr/bin/hbbr -k _
WorkingDirectory=/var/lib/rustdesk-server/
User=${uname}
Group=${uname}
Restart=always
StandardOutput=append:/var/log/rustdesk-server/hbbr.log
StandardError=append:/var/log/rustdesk-server/hbbr.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdeskhbbr}" | sudo tee /etc/systemd/system/rustdesk-hbbr.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable rustdesk-hbbr.service
sudo systemctl start rustdesk-hbbr.service

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$(sudo systemctl status rustdesk-hbbr.service | grep "Active: active (running)")
  echo -ne "Rustdesk Relay not ready yet...${NC}\n"
  sleep 3
done

pubname=$(find /var/lib/rustdesk-server/ -name "*.pub")
key=$(cat "${pubname}")

echo "Tidying up install"
if [ "${ARCH}" = "x86_64" ] ; then
rm rustdesk-server-linux-amd64.zip
rm -rf amd64
elif [ "${ARCH}" = "armv7l" ] ; then
rm rustdesk-server-linux-armv7.zip
rm -rf armv7
elif [ "${ARCH}" = "aarch64" ] ; then
rm rustdesk-server-linux-arm64v8.zip
rm -rf arm64v8
fi


echo -e "Done"
