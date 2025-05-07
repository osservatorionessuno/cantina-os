#! /bin/sh
set -eu

# default hostname
echo "amnesic-cantina" > /etc/hostname
echo "nameserver 64.190.76.5" > /etc/resolv.conf

systemctl disable tor
systemctl enable systemd-networkd
systemctl enable nftables
systemctl enable patela

apt update
apt dist-upgrade -y
