#!/bin/bash -x


if [ -z "${1}" ];then
  echo ""
  #echo " ./virt-install.sh <vmname> <disc in GB> <vcpus> <ram>"
  echo " ./ds-install.sh shortname ds (short for ds.example.org)
  echo ""
  echo "Ex: ./virt-install.sh testvm
  #echo "Ex: ./virt-install.sh testvm 10 2 2048"
  echo ""
  echo "Make sure you have an entry in uteeg/etc/hosts for your vmname"
  echo "Only run one of these at a time. Building multiple"
  echo "VM's gets all wacky with the libvirtd restart and "
  echo "starting and stopping the network"
  echo ""
  echo "All the starting and stopping is to get dhcp leases straight"
  echo ""
  echo ""
  exit 1
fi


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
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm # just need this for facter. ugh.

firewall-cmd --permanent --add-port={389/tcp,636/tcp,9830/tcp}
firewall-cmd --reload

#this set vars per vm from hosts file based on $1, vmname used to launch this script
#use ^ in search to make sure you're not getting comments #
inputfile=../etc/hosts
VMNAME=$(awk /"^${1}"/'{print $1}' "${inputfile}")
DISC_SIZE=$(awk /"^${1}"/'{print $2}' "${inputfile}")
VCPUS=$(awk /"^${1}"/'{print $3}' "${inputfile}")
RAM=$(awk /"^${1}"/'{print $4}' "${inputfile}")
IP=$(awk /"^${1}"/'{print $5}' "${inputfile}")
OS=$(awk /"^${1}"/'{print $6}' "${inputfile}")
RHVER=$(awk /"^${1}"/'{print $7}' "${inputfile}")
OSVARIANT=$(awk /"^${1}"/'{print $8}' "${inputfile}")
VIRTHOST=$(awk /"^${1}"/'{print $9}' "${inputfile}")
DOMAIN=$(awk /"^${1}"/'{print $10}' "${inputfile}")
DISC=$(awk /"^${1}"/'{print $11}' "${inputfile}")
NIC=$(awk /"^${1}"/'{print $12}' "${inputfile}")
MASK=$(awk /"^${1}"/'{print $13}' "${inputfile}")
ISO=$(awk /"^${1}"/'{print $14}' "${inputfile}")
MEDIA=$(awk /"^${1}"/'{print $15}' "${inputfile}")
NETWORK=$(awk /"^${1}"/'{print $16}' "${inputfile}")

DC1=$(echo ${DOMAIN} | awk -F. '{print $1}')
DC2=$(echo ${DOMAIN} | awk -F. '{print $2}')

#cmd has_value VMNAME
#cmd has_value DISC_SIZE
#cmd has_value VCPUS
#cmd has_value RAM
#cmd has_value IP
#cmd has_value OS
#cmd has_value RHVER
#cmd has_value OSVARIANT
#cmd has_value VIRTHOST
#cmd has_value DISC
#cmd has_value NIC
#cmd has_value MASK
#cmd has_value ISO
#cmd has_value MEDIA
#cmd has_value NETWORK

cat << "EOF" > /root/ds.config
[General]
FullMachineName=         <VMNAME>.<DOMAIN>
SuiteSpotUserID=         dirsrv
SuiteSpotGroup=          dirsrv
AdminDomain=             <DOMAIN>
ConfigDirectoryAdminID=  admin
ConfigDirectoryAdminPwd= P@$$w0rd
ConfigDirectoryLdapURL=  ldap://<VMNAME>.<DOMAIN>:389/o=NetscapeRoot
[slapd]
SlapdConfigForMC=        Yes
UseExistingMC=           0
ServerPort=              389
ServerIdentifier=        <VMNAME>
Suffix=                  dc=<DC1>,dc=<DC2>
RootDN=                  cn="Directory Manager"
RootDNPwd=               P@$$w0rd
InstallLdifFile=         suggest
AddOrgEntries=           Yes
[admin]
SysUser=                 dirsrv
Port=                    9830
ServerIpAddress=         <IP>
ServerAdminID=           admin
ServerAdminPwd=          P@$$w0rd
EOF

/usr/bin/sed -i "s/<DC1>/${DC1}/g" /root/ds.config
/usr/bin/sed -i "s/<DC2>/${DC2}/g" /root/ds.config
/usr/bin/sed -i "s/<IP>/${IP}/g" /root/ds.config
/usr/bin/sed -i "s/<VMNAME>/${VMNAME}/g" /root/ds.config
/usr/bin/sed -i "s/<DOMAIN>/${DOMAIN}/g" /root/ds.config

# cleanup to do reinstall
pkill dirsrv
pkill httpd
pkill ns-slapd

rm -rf /etc/dirsrv
/usr/bin/yum -y reinstall redhat-ds 389-ds-console 389-console 389-admin 389-admin-console 389-ds-base

setup-ds-admin.pl --file=/root/ds.config -d --continue --silent

#systemctl enable dirsrv-admin
#systemctl enable dirsrv@${VMNAME}

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
