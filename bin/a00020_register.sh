#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
#source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
#source ../etc/register_cdn.cfg

cd /root && wget --no-clobber http://${SERVER}/passwd
cd /root && wget --no-clobber http://${SERVER}/rhn-acct

#exec >> ../log/virt_inst.log 2>&1
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> ../log/virt-inst.log; done; }
exec 2> >(LOG_)

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

/root/uteeg/a00010_satellite-install.sh
/root/uteeg/bin/b00010_satellite-update.sh
/root/uteeg/bin/b00020_create_Lifecycle_Environments.sh
/root/uteeg/bin/b00030_create_Domain.sh
/root/uteeg/bin/b00040_create_Subnet.sh
/root/uteeg/bin/b00060_create_Compute_Resource.sh
/root/uteeg/bin/c00010_enable_Product_RHEL.sh
/root/uteeg/bin/c00020_create_Content_Views_RHEL.sh
/root/uteeg/bin/d00010_create_Composite_Content_Views.sh
/root/uteeg/bin/d00020_create_Host_Collections.sh
/root/uteeg/bin/e00010_promote_Content_Views.sh
/root/uteeg/bin/f00010_create_Activation_Keys.sh
/root/uteeg/bin/f00020_add_Media.sh
/root/uteeg/bin/g00010_create_Host_Groups.sh

# step 2 put the orig rc.local in place and reboot
cp /root/rc.local.orig /etc/rc.local
EOH

chmod 0755 /etc/rc.local
/sbin/reboot
exit 0
