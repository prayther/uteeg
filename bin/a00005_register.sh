#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

cd /root && wget --no-clobber http://${SERVER}/passwd
cd /root && wget --no-clobber http://${SERVER}/rhn-acct

# After initial install using local media.
# Turn off the local repos and patch from CDN.
mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.

# Unregister so if your are testing over and over you don't run out of subscriptions and annoy folks.
# Register.
/usr/sbin/subscription-manager unregister
#/usr/sbin/subscription-manager --username=$(cat rhn-acct) --password=$(cat passwd) register || echo "subscription-manager register failed" && exit 2
/usr/sbin/subscription-manager --username=$(cat rhn-acct) --password=$(cat passwd) register
/usr/sbin/subscription-manager attach --pool="${RHN_POOL}" || echo "subscription-manager attach --pool failed" && exit 3
/usr/sbin/subscription-manager repos '--disable=*' || echo "subscription-manager repos --disable=* failed" && exit 4
/usr/sbin/subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms || echo "subscription-manager repos --enable failed" && exit 5
/usr/bin/yum clean all
/usr/bin/yum -y update

#/bin/bash /root/uteeg/bin/rc.local.rewrite.sh

#cat << EOH1 > /etc/rc.d/rc.local
##!/bin/bash -x
#
#export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
#export HOME=/root
#cd "${BASH_SOURCE%/*}"
#LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> /root/ks_virt-inst.log; done; }
#exec 2> >(LOG_)
#
#source ../etc/virt-inst.cfg
#
## run all the install/cfg scripts in sequence. the names determine order.
#cd /root/uteeg/bin && $(find /root/uteeg/bin -type f | sort -n | grep -vi .off)
#
## step 2 put the orig rc.local in place and reboot
#cp /root/rc.local.orig /etc/rc.local
#EOH1
#
#chmod 0755 /etc/rc.local
#/sbin/reboot
exit 0
