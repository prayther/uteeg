#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

# bsfl are bash libs used in scripts in uteeg
ls -d ~/bsfl || git clone https://github.com/SkypLabs/bsfl.git /root/bsfl

# read configuration (needs to be adopted!)
#source etc/virt-inst.cfg
source ../etc/virthost.cfg
source ../etc/rhel.cfg
source ~/bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "pace" ]];then
 echo ""
 echo "Need to run this on the 'gfs' node"
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

yum -y install pcs pacemaker fence-agents-all
#yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm # just need this for facter. ugh.

firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload

echo "password" | passwd "hacluster" --stdin

systemctl start pcsd.service
systemctl enable pcsd.service

#[root@z1 ~]# pcs cluster auth z1.example.com z2.example.com
#Username: hacluster
#Password:
#z1.example.com: Authorized
#z2.example.com: Authorized

#[root@z1 ~]# pcs cluster setup --start --name my_cluster \
#z1.example.com z2.example.com

#pcs cluster enable --all

#pcs cluster status
