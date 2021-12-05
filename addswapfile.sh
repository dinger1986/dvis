#!/bin/bash

### Ubuntu 20.04 Check

UBU20=$(grep 20.04 "/etc/"*"release")
if ! [[ $UBU20 ]]; then
  echo -ne "\033[0;31mThis script will only work on Ubuntu 20.04\e[0m\n"
  exit 1
fi

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

addswap="$(cat << EOF
/swapfile swap swap defaults 0 0
EOF
)"
echo "${addswap}" | tee --append /etc/fstab > /dev/null
