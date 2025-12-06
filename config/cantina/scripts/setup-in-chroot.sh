#! /bin/sh
set -eu

# default hostname
echo "on-amnesic-cantina" > /etc/hostname
echo "nameserver 64.190.76.5" > /etc/resolv.conf

systemctl daemon-reload

systemctl disable tor
systemctl enable systemd-networkd
systemctl disable systemd-networkd-wait-online.service
systemctl enable systemd-networkd-wait-online@eno0.service
systemctl enable nftables
systemctl enable patela.timer
systemctl enable chrony

apt update
apt dist-upgrade -y
