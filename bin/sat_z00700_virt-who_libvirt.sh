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

#have to have ssh keys setup for root to libvirt host: ssh-copy-key 10.0.0.1 (libvirt host)

# configure virt-who
#if [ -f /etc/virt-who.d/$(hostname).conf ];then
#ls /etc/virt-who.d/$(hostname).conf || cat << EOF > /etc/virt-who.d/$(hostname).conf
cat << EOF > /etc/virt-who.d/$(hostname).conf
[$(hostname)]
type=libvirt
hypervisor_id=hostname
owner=redhat
env=Library
server=10.0.0.1
username=root
encrypted_password=7c4dc5ac3653b3aa71346c09fd943e78
rhsm_hostname=sat62.prayther.org
rhsm_username=admin
rhsm_encrypted_password=80d4326276fd47f13eed914c74a265dd
rhsm_prefix=/rhsm
EOF
#fi

# config satellite 6 if not already
grep -i "^VIRTWHO_SATELLITE6=1" /etc/sysconfig/virt-who || echo "VIRTWHO_SATELLITE6=1" >> /etc/sysconfig/virt-who
#sed search and replace
sed -i 's/^VIRTWHO_DEBUG=0/VIRTWHO_DEBUG=1/g' /etc/sysconfig/virt-who

virt-who --one-shot
/usr/bin/systemctl enable virt-who
/usr/bin/systemctl restart virt-who
#journalctl -u virt-who -f

# find virt-who host
# this is only set to work with "1" host for testing.
setup_slow_vars () {
                    VIRT_HOST=$(hammer --csv host list | grep virt-who | awk -F"," '{print $2}')
                    SUBS_var=$(hammer --csv subscription list --organization "${ORG}"| awk -F"," '{print $1}'| sort -n | grep -v ID)
	    }
setup_slow_vars

add_subs () {
	for SUBS in ${SUBS_var}; do
          hammer host subscription attach --host "${VIRT_HOST}" --subscription-id ${SUBS}
        done
}
add_subs

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
