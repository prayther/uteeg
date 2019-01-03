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

pcs cluster auth pace-01.example.org pace-02.example.org -u hacluster -p password

#[root@z1 ~]# pcs cluster setup --start --name my_cluster \
#z1.example.com z2.example.com

pcs cluster setup --start --name my_cluster \
	pace-01.example.org pace-02.example.org

pcs cluster enable --all

mkdir -p /etc/cluster

#on kvm host
#dnf install fence-virt fence-virtd fence-virtd-libvirt fence-virtd-multicast fence-virtd-serial

#mkdir -p /etc/cluster
#cd /etc/cluster/
#dd if=/dev/urandom of=/etc/cluster/fence_xvm.key bs=4k count=1
#scp -r /etc/cluster/fence_xvm.key root@pace-01:/etc/cluster/fence_xvm.key
#scp -r /etc/cluster/fence_xvm.key root@pace-02:/etc/cluster/fence_xvm.key


pcs resource create ClusterIP ocf:heartbeat:IPaddr2 \
    ip=10.0.0.42 cidr_netmask=24 op monitor interval=30s

#disable fencing for testing
pcs property set stonith-enabled=false

pcs cluster status
