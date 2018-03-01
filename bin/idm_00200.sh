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
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "gfs" ]];then
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
# admin node: non interactive, emptly pass ""
if [[ $(hostname -s | awk -F"-" '{print $2}') -eq "admin" ]];then
        ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
        ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
fi

#firewall
/usr/bin/firewall-cmd --permanent --add-port={80/tcp,443/tcp,389/tcp,636/tcp,53/tcp,53/udp,123/udp}
/usr/bin/firewall-cmd --reload

#configure ipa-server
/usr/sbin/ipa-server-install --unattended --ds-password=password --admin-password=password --domain=example.org --realm=EXAMPLE.ORG --hostname=$(hostname) --setup-dns --mkhomedir --ssh-trust-dns --auto-forwarders

#==============================================================================
#Setup complete
#
#Next steps:
#	1. You must make sure these network ports are open:
#		TCP Ports:
#		  * 80, 443: HTTP/HTTPS
#		  * 389, 636: LDAP/LDAPS
#		  * 88, 464: kerberos
#		  * 53: bind
#		UDP Ports:
#		  * 88, 464: kerberos
#		  * 53: bind
#		  * 123: ntp
#
#	2. You can now obtain a kerberos ticket using the command: 'kinit admin'
#	   This ticket will allow you to use the IPA tools (e.g., ipa user-add)
#	   and the web user interface.
#
#Be sure to back up the CA certificates stored in /root/cacert.p12
#These files are required to create replicas. The password for these
#files is the Directory Manager password


echo "###INFO: Finished $0"
echo "###INFO: $(date)"
