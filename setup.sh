#!/bin/bash
setenforce 0
sed -i 's@enforcing@permissive@g' /etc/selinux/config
yum -y install bind haproxy bind-utils nfsutils
mkdir /etc/named/zones
cp named.conf /etc/named.conf
cp named.conf.local /etc/named/named.conf.local
cp db* /etc/named/zones
cp haproxy.cfg /etc/haproxy.cfg
systemctl enable --now named
systemctl enable --now haproxy

