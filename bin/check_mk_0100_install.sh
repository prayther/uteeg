#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
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
export HOME=/root


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
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "checkmk" ]];then
 echo ""
 echo "Need to run this on the 'gfs' node"
 echo ""
 exit 1
fi

if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
 echo ""
 echo "Need to run this on the 'admin' node"
 echo ""
 exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi
####################################################################################
#Check_MK / OMD server install/cfg
firewall-cmd --add-port=80/tcp --add-port=6556/tcp --permanent
firewall-cmd --reload
#subscription-manager repos --enable rhel-7-server-optional-rpms --enable rhel-7-server-extras-rpms
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
yum install http://"${GATEWAY}"/ks/apps/check_mk/check-mk-raw-1.4.0p10-el7-57.x86_64.rpm -y
#yum install http://"${GATEWAY}"/ks/apps/check_mk/check-mk-raw*
#omd create dev
#omd start dev
#systemctl status omd
#htpasswd -m ~/etc/htpasswd cmkadmin' as site user
#cmkadmin with password: ZSllOAuI
#htpasswd -b /opt/omd/sites/dev/etc/htpasswd cmkadmin redhat

#Client cfg
#check_mk plugin
#yum install -y http://$(hostname)/dev/check_mk/agents/check-mk-agent-1.4.0p10-1.noarch.rpm
#yum install -y http://checkmk-admin/dev/check_mk/agents/check-mk-agent-1.4.0p10-1.noarch.rpm
#firewall-cmd --add-port=6556/tcp --permanent
#systemctl status xinetd

#snmp
yum install -y net-snmp net-snmp-utils net-snmp-libs net-snmp-devel
net-snmp-config --create-snmpv3-user -A 12345678 -X 12345678 -a MD5 -x DES admin
systemctl enable snmpd
systemctl restart snmpd
snmpwalk -v3 -u admin -l authNoPriv -a MD5 -x DES -A 12345678 -X 12345678 localhost
firewall-cmd --add-service=snmp --permanent
firewall-cmd --reload
iptables -nL
systemctl status snmpd

#check_mk/omd does not like selinux
setenforce permissive
#sed search and replace SELINUX=enforcing with SELINUX=permissive
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

#loginto the http://$(hostname)/dev/ #dev is the site name used above to create the omd site
#got to WATO - Configuration menu -> Hosts
#Create a folder and get it an ip range and snmp credential.
#set all the defaults like 'important' server and enable monitoring
#auto discovers your machines

omd create dev
omd start dev
systemctl status omd
#htpasswd -m ~/etc/htpasswd cmkadmin' as site user
#cmkadmin with password: ZSllOAuI
htpasswd -b /opt/omd/sites/dev/etc/htpasswd cmkadmin redhat
echo "#loginto the http://$(hostname)/dev/ #dev is the site name used above to create the omd site
#got to WATO - Configuration menu -> Hosts
#Create a folder and get it an ip range and snmp credential.
#set all the defaults like 'important' server and enable monitoring
#auto discovers your machines
"

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
