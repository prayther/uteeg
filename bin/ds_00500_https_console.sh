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

<<COMMENT
#restart to confirm things work now.
systemctl restart dirsrv@ds-stig
systemctl status dirsrv@ds-stig
systemctl restart dirsrv-admin
systemctl status dirsrv-admin

#E.2.7.1.1. Using the Directory Server Private Key and Certificate for the Admin Server
systemctl stop dirsrv-admin
systemctl stop dirsrv@ds-stig

#List the contents of the Directory Server NSS database:
certutil -L -d /etc/dirsrv/admin-serv/

#Setup https for console
#Export the private key and certificate with the name server-cert from the Directory Server's PKI database:
pk12util -o /tmp/keys.pk12 -n server-cert -d /etc/dirsrv/slapd-ds-stig/

#Import the private key and certificate into the Administration Server's PKI database:
pk12util -i /tmp/keys.pk12 -d /etc/dirsrv/admin-serv/

#Trust the Demo CA:
certutil -M -d /etc/dirsrv/admin-serv/ -n "server-cert" -t CT,,

#Delete the temporarily exported file:
rm -f /tmp/keys.pk12

#start services
systemctl restart dirsrv@ds-stig
systemctl restart dirsrv-admin

#Create a password file named password.conf. The file should include a line with the token name and password, in the form token:password
#identify the admin user
cd /etc/dirsrv/admin-serv/
grep \^User console.conf
#User dirsrv

echo 'internal:P@$$w0rd' > /etc/dirsrv/admin-serv/password.conf
chown dirsrv.dirsrv /etc/dirsrv/admin-serv/password.conf
chmod 0400 /etc/dirsrv/admin-serv/password.conf

/bin/sed '/^NSSPassPhraseDialog/ s/builtin/file\:\/\/etc\/dirsrv\/admin-serv\/password.conf/g' /etc/dirsrv/admin-serv/nss.conf > /etc/dirsrv/admin-serv/nss.conf.sed
/bin/cp /etc/dirsrv/admin-serv/nss.conf /etc/dirsrv/admin-serv/nss.conf.orig
/bin/cp /etc/dirsrv/admin-serv/nss.conf.sed /etc/dirsrv/admin-serv/nss.conf

#systemctl enable dirsrv-admin.service
systemctl restart dirsrv-admin.service
systemctl status dirsrv-admin.service

#9.8.1. Setting up Certificate-based User Authentication
#https://access.redhat.com/documentation/en-us/red_hat_directory_server/10/html-single/administration_guide/#Managing_Replication-Configuring_Multi_Master_Replication

COMMENT

#systemctl enable dirsrv@ds-stig
systemctl restart dirsrv@ds-stig
systemctl status dirsrv@ds-stig

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
