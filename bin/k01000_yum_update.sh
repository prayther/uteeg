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


doit /usr/bin/yum clean all
doit /usr/bin/yum -y update
# - name: update system
#    yum: name=* state=latest
#    notify:
#     - Restart server
#     - Wait for server to restart

echo "###INFO: Finished $0"
echo "###INFO: $(date)"

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
#exit 0
