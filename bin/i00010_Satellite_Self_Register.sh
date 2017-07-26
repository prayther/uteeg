#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg

#exec >> ../log/virt_inst.log 2>&1
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> ../log/virt-inst.log; done; }
exec 2> >(LOG_)

/usr/sbin/subscription-manager unregister
rpm -Uvh /var/www/html/pub/katello-ca-consumer-latest.noarch.rpm
#/usr/sbin/subscription-manager --username=admin --password=password register --activationkey=
/usr/sbin/subscription-manager --username=admin --password=password register --environment Library
#/usr/sbin/subscription-manager attach --pool="${RHN_POOL}"     #8a85f9873f77744e013f8944ab87680b
#/usr/sbin/subscription-manager repos '--disable=*'
#/usr/sbin/subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms

