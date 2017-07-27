#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

subscription-manager unregister
rpm -Uvh /var/www/html/pub/katello-ca-consumer-latest.noarch.rpm
# add a activation key once i get satellite repos in my test bed.
#/usr/sbin/subscription-manager --username=admin --password=password register --activationkey=
