#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg

cd /root && wget --no-clobber http://${SERVER}/passwd
cd /root && wget --no-clobber http://${SERVER}/rhn-acct

exec >> ../log/register.log 2>&1

# After initial install using local media.
# Turn off the local repos and patch from CDN.
mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.

# Unregister so if your are testing over and over you don't run out of subscriptions and annoy folks.
# Register.
/usr/sbin/subscription-manager unregister
/usr/sbin/subscription-manager --username=$(cat rhn-acct) --password=$(cat passwd) register
/usr/sbin/subscription-manager attach --pool="${RHN_POOL}"     #8a85f9873f77744e013f8944ab87680b
/usr/sbin/subscription-manager repos '--disable=*'
/usr/sbin/subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms
/usr/bin/yum repolist
/usr/bin/yum clean all
/usr/bin/yum -y update

#/bin/bash /root/uteeg/bin/rc.local.rewrite.sh

cat << EOH > /etc/rc.d/rc.local
#!/bin/bash

# run commands together so they don't run at the same time.
/bin/bash /root/uteeg/satellite-install.sh
/bin/bash /root/uteeg/bin/satellite-update.sh
/bin/bash /root/uteeg/bin/enable_rhel.sh
/bin/bash /root/uteeg/bin/5
/bin/bash /root/uteeg/bin/6
/bin/bash /root/uteeg/bin/7
/bin/bash /root/uteeg/bin/8

# step 2 put the orig rc.local in place and reboot
cp /root/rc.local.orig /etc/rc.local
EOH

chmod 0755 /etc/rc.local
/sbin/reboot
exit 0
