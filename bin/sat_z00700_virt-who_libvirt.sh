#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

logfile="../log/$(basename $0 .sh).log"
donefile="../log/$(basename $0 .sh).done"
touch $logfile
touch $donefile

exec > >(tee -a "$logfile") 2>&1

echo "###INFO: Starting $0"
echo "###INFO: $(date)"

# read configuration (needs to be adopted!)
#. ./satenv.sh
source ../etc/virt-inst.cfg


doit() {
        echo "INFO: doit: $@" >&2
        cmd2grep=$(echo "$*" | sed -e 's/\\//' | tr '\n' ' ')
        grep -q "$cmd2grep" $donefile
        if [ $? -eq 0 ] ; then
                echo "INFO: doit: found cmd in donefile - skipping" >&2
        else
                "$@" 2>&1 || {
                        echo "ERROR: cmd was unsuccessfull RC: $? - bailing out" >&2
                        exit 1
                }
                echo "$cmd2grep" >> $donefile
                echo "INFO: doit: cmd finished successfull" >&2
        fi
}

# Install virt-who if it's not already
rpm -q virt-who || doit /usr/bin/yum install -y virt-who

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
/usr/bin/systemctl restart virt-who
#journalctl -u virt-who -f

# find virt-who host
# this is only set to work with "1" host for testing.
setup_slow_vars () {
                    VIRT_HOST=$(hammer --csv host list | grep virt-who | awk -F"," '{print $2}')
                    SUBS_var=$(hammer --csv subscription list --organization "${ORG}"| awk -F"," '{print $1}'| sort -n | grep -v ID)
	    }
doit setup_slow_vars

add_subs () {
	for SUBS in ${SUBS_var}; do
          hammer host subscription attach --host ${VIRT_HOST} --subscription-id ${SUBS}
        done
}
doit add_subs

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
