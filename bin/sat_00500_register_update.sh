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

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "sat" ]];then
 echo ""
 echo "Need to run this on the 'sat' node"
 echo ""
 exit 1
fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

wget -P /root/ --no-clobber http://${SERVER}/passwd
wget -P /root/ --no-clobber http://${SERVER}/rhn-acct

# Unregister so if your are testing over and over you don't run out of subscriptions and annoy folks.
# Register.
subscribe_update () {
  /usr/sbin/subscription-manager unregister
  /usr/sbin/subscription-manager --username=$(cat /root/rhn-acct) --password=$(cat /root/passwd) register
  # Satellite
  /usr/sbin/subscription-manager attach --pool=$(subscription-manager list --available | awk '/Red Hat Satellite/,/Pool ID/'  | grep "Pool ID:" | head -1 | awk ' { print $NF } ')
  # Ceph
  #/usr/sbin/subscription-manager attach --pool=$(subscription-manager list --available | awk '/Red Hat Ceph Storage/,/Pool ID/'  | grep "Pool ID:" | head -1 | awk ' { print $NF } ')
  /usr/sbin/subscription-manager repos '--disable=*' --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms

  #Clean, update
  /usr/bin/yum clean all
  rm -rf /var/cache/yum
  /usr/bin/yum -y update
}
time subscribe_update

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
