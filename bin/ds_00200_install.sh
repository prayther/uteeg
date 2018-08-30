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

yum -y install redhat-ds 389-ds-base-snmp

firewall-cmd --permanent --add-port={389/tcp,636/tcp,9830/tcp}
firewall-cmd --reload

setup-ds-admin.pl --file=$(cat << "EOF" > /root/ds.config
[General] 
FullMachineName= $(hostname -s).$(DOMAIN)
SuiteSpotUserID= dirsrv
SuiteSpotGroup= dirsrv
AdminDomain= $(DOMAIN)
ConfigDirectoryAdminID= admin 
ConfigDirectoryAdminPwd= admin 
ConfigDirectoryLdapURL= ldap://$(/usr/bin/hostname -s).$(DOMAIN):389/o=NetscapeRoot 

[slapd] 
SlapdConfigForMC= Yes 
UseExistingMC= 0 
ServerPort= 389 
ServerIdentifier= dir 
Suffix= dc=$(facter domain | awk -F. '{print $1}'),dc=$(facter domain | awk -F. '{print $2}')
RootDN= cn=Directory Manager 
RootDNPwd= password
ds_bename=exampleDB 
AddSampleEntries= No

[admin] 
Port= 9830
ServerIpAddress= $(/usr/bin/facter ip)
ServerAdminID= admin 
ServerAdminPwd= admin
EOF)

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
