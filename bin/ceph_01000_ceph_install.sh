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

#useradd ceph_ansible
#echo "password" | passwd "ceph_ansible" --stdin

#cat << EOF >/etc/sudoers.d/ceph_ansible
#ceph_ansible ALL = (root) NOPASSWD:ALL
#EOF

#chmod 0440 /etc/sudoers.d/ceph_ansible

# non interactive, emptly pass ""
su -c "ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa" ceph_ansible

# get everyone talking for ansible
SSHPASS='password'
for i in admin mon osd2
  do sshpass -e ssh-copy-id -o StrictHostKeyChecking=no -i /home/ceph_ansible/.ssh/id_rsa.pub ceph_ansible@"${i}" && ssh -o StrictHostKeyChecking=no ceph_ansible@"${i}" exit
done


echo "###INFO: Finished $0"
echo "###INFO: $(date)"
