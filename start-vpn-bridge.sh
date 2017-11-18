#!/bin/bash

#
# IP ranges:
# ----------
#
# - WAN (eth0):  Provided by ISP DHCP
# - LAN (wlan0): 10.0.1.0/255 (this machine will be a DHCP server and gateway at 10.0.2.1)
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

echo == LAN interface: =================================
sudo ifconfig wlan0 10.0.1.1 netmask 255.255.255.0 up
ifconfig wlan0

echo == Internet connection sharing: ===================
sudo apt-get -y --force-yes install isc-dhcp-server
sudo cp -f ./dhcpd-vpn.conf /etc/dhcp/dhcpd.conf
sudo cp -f ./isc-dhcp-server-vpn /etc/default/isc-dhcp-server
sudo sysctl net.ipv4.ip_forward=1
sudo /bin/sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo service isc-dhcp-server start
sudo update-rc.d isc-dhcp-server enable

echo == OpenVPN: =======================================
echo TODO

echo == hostapd: =======================================
echo TODO

echo == Package update: ================================
sudo apt-get -y update
sudo apt-get -y upgrade
git pull

