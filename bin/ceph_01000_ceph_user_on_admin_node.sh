#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
#export HOME=/home/"${CEPH_USER}"
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
export HOME=/home/"${CEPH_USER}"


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

if [[ $(id -u) -eq "0" ]];then
	echo "Don't run as root"
	echo
	echo "Run as Ceph User: $(ls /home | grep -i ceph)"
	exit 1
fi

#sudo setenforce 0
#useradd ceph_ansible
#echo "password" | passwd "ceph_ansible" --stdin

#cat << EOF >/etc/sudoers.d/ceph_ansible
#ceph_ansible ALL = (root) NOPASSWD:ALL
#EOF

#chmod 0440 /etc/sudoers.d/ceph_ansible

sudo yum -y install ceph-deploy sshpass yum-plugin-priorities

# non interactive, emptly pass ""
#su -c "ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa" ceph_ansible
ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa

# get everyone talking for ansible
for i in node1 node2 node3
  do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${CEPH_USER}"@"${i}"
  ssh "${CEPH_USER}"@"${i}" sudo firewall-cmd --zone=public --add-port=6789/tcp --permanent
done

#Clean up from previous run, destroying everything
ceph-deploy disk zap node1:vdb node2:vdb node3:vdb
ceph-deploy uninstall node1 node2 node3
ceph-deploy purgedata node1 node2 node3

#clear partition on vdb **danger**
#for i in node1 node2 node3
#  do echo "d
#
#d
#
#d
#
#w
#
#"| ssh ${i} "sudo fdisk /dev/vdb"
#done

cd ~/my-cluster && ceph-deploy forgetkeys
cd ~/my-cluster && rm -f ceph*

#Create a directory on your admin node node for maintaining the configuration files and keys that ceph-deploy generates for your cluster.
cd ~ && mkdir my-cluster
cd ~/my-cluster && ceph-deploy new node1
cd ~/my-cluster && ceph-deploy install node1 node2 node3
cd ~/my-cluster && ceph-deploy mon create-initial
cd ~/my-cluster && ceph-deploy admin node1 node2 node3
cd ~/my-cluster && ceph-deploy osd create node1:vdb node2:vdb node3:vdb
#ssh node1 sudo ceph health
#ssh node1 sudo ceph -s

#Expand cluster
#ceph-deploy mds create node1
#ceph-deploy mon add node2
#ceph-deploy mon add node3
#ssh node1 sudo ceph quorum_status --format json-pretty

#sudo setenforce 1

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
