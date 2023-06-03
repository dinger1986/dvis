#!/bin/bash

SWAPSIZE=$1

sudo fallocate -l ${SWAPSIZE} /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

addswap="$(cat << EOF
/swapfile swap swap defaults 0 0
EOF
)"
echo "${addswap}" | sudo tee --append /etc/fstab > /dev/null
