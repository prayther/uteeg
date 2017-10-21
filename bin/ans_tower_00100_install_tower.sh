#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

# bsfl are bash libs used in scripts in uteeg
ls -d ~/bsfl || git clone https://github.com/SkypLabs/bsfl.git /root/bsfl

# read configuration (needs to be adopted!)
#source etc/virt-inst.cfg
source ../etc/virt-inst.cfg
source ../etc/virthost.cfg
source ../etc/rhel.cfg
source ~/bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"0" '{print $1}') -ne "ans" ]];then
 echo ""
 echo "Need to run this on the 'gfs' node"
 echo ""
 exit 1
fi

if [[ $(hostname -s | awk -F"0" '{print $2}') -ne "tower" ]];then
 echo ""
 echo "Need to run this on the 'tower' node"
 echo ""
 exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

wget -P /root/ --no-clobber http://"${GATEWAY}"/ks/apps/tower/ansible-tower-setup-latest.tar.gz
tar zxvf /root/ansible-tower-setup-latest.tar.gz
sed -i "s/admin_password=.*/admin_password='password'/g" /root/ansible-tower-setup-3.2.1/inventory
sed -i "s/pg_password=.*/pg_password='password'/g" /root/ansible-tower-setup-3.2.1/inventory
sed -i "s/rabbitmq_password=.*/rabbitmq_password='password'/g" /root/ansible-tower-setup-3.2.1/inventory

/root/ansible-tower-setup-3.2.1/setup.sh

yum -y install python-pip
pip install --upgrade pip
pip install ansible-tower-cli
#yum -y install ansible
#ansible --version

#su -c "mkdir -pv ~/lab/inventory" user

#su -c "cat << "EOF" > ~/lab/ansible.cfg
#[defaults]
#remote_user = user
#inventory = inventory

#[privilege_escalation]
#become = False
#become_method = sudo
#become_user = root
#become_ask_pass = False
#EOF" user

#su -c "cat << "EOF" > ~/lab/ansible.cfg
#[intranetweb]
#ansible-node1

#[everyone:children]
#intranetweb
#EOF" user

#ansible everyone -m command -a 'id'
