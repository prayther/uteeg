#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
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


#source etc/virt-inst.cfg
source ../etc/virthost.cfg
source ../etc/rhel.cfg
source ~/bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

yum -y install ansible
ansible --version

#seutp /etc/ansible/hosts file
if [ ! -f /etc/ansible/hosts.uteeg ];then
	cp /etc/ansible/hosts /etc/ansible/hosts.uteeg
fi

cat << "EOF" >/etc/ansible/hosts
[webservers]
server[a:d].lab.example.com

[raleigh]
servera.lab.example.com
serverb.lab.example.com

[mountainview]
serverc.lab.example.com

[london]
serverd.lab.example.com

[development]
servera.lab.example.com

[testing]
serverb.lab.example.com

[production]
serverc.lab.example.com
serverd.lab.example.com

[us:children]
raleigh
mountainview
EOF

ansible all --list-hosts

ansible everyone -m command -a 'id'

#https://docs.openstack.org/ansible-hardening/latest/getting-started.html
#ansible-galaxy install git+https://github.com/openstack/ansible-hardening
#on tower /var/lib/awx/projects/*ansible-hardening/tests/test.yml change host from localhost to 'all'
#then filter in tower for template can, test02.prayther.org
#cat << "EOF" >/root/ansible-hardening.yml
#---
#
#- name: Harden all systems
##  hosts: all
#  hosts: localhost
#  become: yes
##  vars:
##    security_enable_firewalld: no
##    security_rhel7_initialize_aide: no
##    security_ntp_servers:
##      - 1.example.com
##      - 2.example.com
#  roles:
#    - ansible-hardening
#EOF

#uncomment /etc/ansible/ansible.cfg log_path = /var/log/ansible.log to get logs
#ansible-playbook -i "localhost," -c local harden.yml
#[root@ans0tower _17__ansible_hardening]# scp /usr/share/awx/request_tower_configuration.sh test02:
#./request_tower_configuration.sh -k -s https://ans0tower.prayther.org -c 9d449298a04321be6a5466ca752d718c -t 5
