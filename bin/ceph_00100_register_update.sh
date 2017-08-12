#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes 
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

# The first time this runs is from rc.local and a reboot direclty after

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


wget -P /root/ --no-clobber http://${SERVER}/passwd
wget -P /root/ --no-clobber http://${SERVER}/rhn-acct

useradd ceph_ansible
useradd apraythe

cat << EOF >/etc/sudoers.d/ceph_ansible
ceph_ansible ALL = (root) NOPASSWD:ALL
apraythe ALL = (root) NOPASSWD:ALL
EOF

chmod 0440 /etc/sudoers.d/ceph_ansible


# Unregister so if your are testing over and over you don't run out of subscriptions and annoy folks.
# Register.
subscribe_update () {
  /usr/sbin/subscription-manager unregister
  /usr/sbin/subscription-manager --username=$(cat /root/rhn-acct) --password=$(cat /root/passwd) register
  # Satellite
  #/usr/sbin/subscription-manager attach --pool=$(subscription-manager list --available | awk '/Red Hat Satellite/,/Pool ID/'  | grep "Pool ID:" | head -1 | awk ' { print $NF } ')
  # Ceph
  /usr/sbin/subscription-manager attach --pool=$(subscription-manager list --available | awk '/Red Hat Ceph Storage/,/Pool ID/'  | grep "Pool ID:" | head -1 | awk ' { print $NF } ')
  /usr/sbin/subscription-manager repos '--disable=*' --enable=rhel-7-server-rpms --enable=rhel-7-server-rhceph-2-mon-rpms --enable=rhel-7-server-rhceph-2-osd-rpms --enable=rhel-7-server-rhceph-2-tools-rpms --enable=rhel-7-server-rhscon-2-agent-rpms --enable=rhel-7-server-rhscon-2-installer-rpms

  #Clean, update
  /usr/bin/yum clean all
  rm -rf /var/cache/yum
  /usr/bin/yum -y update
}
time subscribe_update

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
