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
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "ansible" ]];then
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

yum -y install ansible
ansible --version

su -c "mkdir -pv ~/lab/inventory" user

su -c "cat << "EOF" > ~/lab/ansible.cfg
[defaults]
remote_user = user
inventory = inventory

[privilege_escalation]
become = False
become_method = sudo
become_user = root
become_ask_pass = False
EOF" user

su -c "cat << "EOF" > ~/lab/ansible.cfg
[intranetweb]
ansible-node1

[everyone:children]
intranetweb
EOF" user

ansible everyone -m command -a 'id'
#https://docs.openstack.org/ansible-hardening/latest/getting-started.html
ansible-galaxy install git+https://github.com/openstack/ansible-hardening
#on tower /var/lib/awx/projects/*ansible-hardening/tests/test.yml change host from localhost to 'all'
#then filter in tower for template can, test02.prayther.org
cat << "EOF" >/root/ansible-hardening.yml
---

- name: Harden all systems
#  hosts: all
  hosts: localhost
  become: yes
#  vars:
#    security_enable_firewalld: no
#    security_rhel7_initialize_aide: no
#    security_ntp_servers:
#      - 1.example.com
#      - 2.example.com
  roles:
    - ansible-hardening
EOF

#uncomment /etc/ansible/ansible.cfg log_path = /var/log/ansible.log to get logs
#ansible-playbook -i "localhost," -c local harden.yml
#[root@ans0tower _17__ansible_hardening]# scp /usr/share/awx/request_tower_configuration.sh test02:
#./request_tower_configuration.sh -k -s https://ans0tower.prayther.org -c 9d449298a04321be6a5466ca752d718c -t 5
