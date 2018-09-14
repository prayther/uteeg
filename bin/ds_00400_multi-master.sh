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

#15.2.1. Configuring Suppliers from the Command Line
#https://access.redhat.com/documentation/en-us/red_hat_directory_server/10/html-single/administration_guide/#Configuring-Replication-Suppliers-cmd
#On the supplier server, use ldapmodify to create the changelog entry.

#supplier of replication
ldapmodify -D "cn=Directory Manager" -W -x -h ds-stig.example.org -v -a
dn: cn=changelog5,cn=config
changetype: add
objectclass: top
objectclass: extensibleObject
cn: changelog5
nsslapd-changelogdir: /var/lib/dirsrv/slapd-ds-stig/changelogdb
nsslapd-changelogmaxage: 10d

#Create the supplier replica.
ldapmodify -D "cn=Directory Manager" -W -x -h ds-stig.example.org -v -a
dn: cn=replica,cn=dc\=example\,dc\=org,cn=mapping tree,cn=config
changetype: add
objectclass: top
objectclass: nsds5replica
objectclass: extensibleObject
cn: replica
nsds5replicaroot: dc=example,dc=org
nsds5replicaid: 7
nsds5replicatype: 3
nsds5flags: 1
nsds5ReplicaPurgeDelay: 604800
nsds5ReplicaBindDN: cn=replication manager,cn=config

#15.2.4. Configuring Replication Agreements from the Command Line
ldapmodify -D "cn=Directory Manager" -W -x -h ds-stig.example.org -v -a
dn: cn=ExampleAgreement,cn=replica,cn=dc\=example\,dc\=org,cn=mapping tree,cn=config
objectclass: top
objectclass: nsds5ReplicationAgreement
cn: ExampleAgreement
nsds5replicahost: ds-repl
nsds5replicaport: 389
nsds5ReplicaBindDN: cn=replication manager,cn=config
nsds5replicabindmethod: SIMPLE
nsds5replicaroot: dc=example,dc=org
description: agreement between ds-stig and ds-repl
nsds5replicaupdateschedule: 0000-0500 1
nsds5replicatedattributelist: (objectclass=*) $ EXCLUDE authorityRevocationList accountUnlockTime memberof
nsDS5ReplicatedAttributeListTotal: (objectclass=*) $ EXCLUDE accountUnlockTime
nsds5replicacredentials: P@$$w0rd

#status
ldapsearch -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -b "cn=ExampleAgreement,cn=replica,cn=dc\=example\,dc\=org,cn=mapping tree,cn=config" nsds5replicaLastUpdateStatus

#15.2.5. Initializing Consumers Online from the Command Line
ldapmodify -D "cn=Directory Manager" -W -x -h ds-stig.example.org -v -a
dn: cn=ExampleAgreement,cn=replica,cn=dc\=example\,dc\=org,cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start

systemctl restart dirsrv@ds-stig
systemctl status dirsrv@ds-stig
systemctl restart dirsrv-admin
systemctl status dirsrv-admin



#here down is for consumer of the replication
#Create the replica entry:
ldapadd -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x
dn: cn=replica,cn=dc\=example\,dc\=org,cn=mapping tree,cn=config
objectclass: top
objectclass: nsds5replica
objectclass: extensibleObject
cn: replica
nsds5replicaroot: dc=example,dc=org
nsds5replicaid: 65535
nsds5replicatype: 2
nsds5ReplicaBindDN: cn=replication manager,cn=config
nsds5flags: 0

ldapadd -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x
dn: cn=dc\=example\,dc\=org,cn=mapping tree,cn=config
changetype: modify
replace: nsslapd-referral
nsslapd-referral: ldap://ds-stig.example.org:389/dc\=example\,dc\=org
-
replace: nsslapd-state
nsslapd-state: referral on update


systemctl restart dirsrv@ds-repl
systemctl status dirsrv@ds-repl
systemctl restart dirsrv-admin
systemctl status dirsrv-admin


echo "###INFO: Finished $0"
echo "###INFO: $(date)"
