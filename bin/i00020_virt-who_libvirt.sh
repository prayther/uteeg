#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# Install virt-who if it's not already
rpm -q virt-who || /usr/bin/yum install -y virt-who

# configure virt-who
if [ ! -f /etc/virt-who.d/${VMNAME}.${DOMAIN}.conf ];then
cat << EOF > /etc/virt-who.d/${VMNAME}.${DOMAIN}.conf
[sat.laptop.prayther]
type=libvirt
#server=sat.laptop.prayther
server=${GATEWAY}
#username=root
#password=password
#encrypted_password=
owner=${ORG}
env=Library
hypervisor_id=hostname
EOF
fi

# config satellite 6 if not already
grep -i "^VIRTWHO_SATELLITE6=1" /etc/sysconfig/virt-who || echo "VIRTWHO_SATELLITE6=1" >> /etc/sysconfig/virt-who

/usr/bin/systemctl enable virt-who
/usr/bin/systemctl start virt-who
#journalctl -u virt-who -f

# find virt-who host
# this is only set to work with "1" host for testing.
VIRT_HOST=$(hammer --csv host list | grep virt-who | awk -F"," '{print $2}')
# list all subs
#hammer --csv subscription list --organization redhat
SUBS_var=$(hammer --csv subscription list --organization "${ORG}"| awk -F"," '{print $1}'| sort -n | grep -v ID)

for SUBS in ${SUBS_var}; do
  hammer host subscription attach --host ${VIRT_HOST} --subscription-id ${SUBS}
done
