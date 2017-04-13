#!/bin/bash

#
# IP ranges:
# ----------
#
# - WAN (eth0):  Provided by ISP DHCP
# - LAN1 (eth1): 10.0.1.0/255 (this machine will be a DHCP server and gateway at 10.0.1.1)
# - LAN2 (eth2): 10.0.2.0/255 (this machine will be a DHCP server and gateway at 10.0.2.1)
# 
# LAN1 routes all traffic through TOR; LAN2 does not.
#

echo == Clear existing iptables rules: =================
sudo iptables -F
sudo iptables -F -t nat
sudo iptables -F -t mangle
sudo iptables -X
sudo iptables -X -t nat
sudo iptables -X -t mangle

echo == Internet interface: ============================
sudo ifconfig eth0 up
sudo dhclient eth0
ifconfig eth0

echo == LAN1 interface: ================================
sudo ifconfig eth1 10.0.1.1 netmask 255.255.255.0 up
ifconfig eth1

echo == LAN2 interface: ================================
sudo ifconfig eth2 10.0.2.1 netmask 255.255.255.0 up
ifconfig eth2

echo == Internet connection sharing: ===================
sudo apt-get -y --force-yes install isc-dhcp-server
sudo cp -f ./dhcpd.conf /etc/dhcp/dhcpd.conf
sudo cp -f ./isc-dhcp-server /etc/default/isc-dhcp-server
sudo sysctl net.ipv4.ip_forward=1
sudo /bin/sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o eth2 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
sudo service isc-dhcp-server start
sudo update-rc.d isc-dhcp-server enable

echo == Tor: ===========================================
sudo apt-get -y install tor
sudo cp -f ./torrc /etc/tor/torrc
sudo service tor restart
sudo iptables -t nat -A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353
sudo iptables -t nat -A PREROUTING -i eth1 -p tcp --syn -j REDIRECT --to-ports 9040
sudo iptables-save>/dev/null

echo == Package update: ================================
sudo apt-get -y update
sudo apt-get -y upgrade
git pull

