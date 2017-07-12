#!/bin/bash -x

cd "${BASH_SOURCE%/*}"
source etc/install-configure-satellite.cfg
source etc/virt-inst.cfg
source etc/register_cdn.cfg

#exec >> log/update.log 2>&1

# Unregister so if your are testing over and over you don't run out of subscriptions and annoy folks.
# Register.
/usr/sbin/subscription-manager unregister
/usr/sbin/subscription-manager --username="${RHN_USERNAME}" --password="${RHN_PASSWD}" register
/usr/sbin/subscription-manager attach --pool="${RHN_POOL}"     #8a85f9873f77744e013f8944ab87680b
/usr/sbin/subscription-manager repos '--disable=*'
/usr/sbin/subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms
/usr/bin/yum repolist
/usr/bin/yum clean all
/usr/bin/yum -y update
/usr/bin/yum -y install nfs-utils

