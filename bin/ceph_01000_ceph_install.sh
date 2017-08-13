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

if [[ $(id -u) -eq "0" ]];then
	echo "Don't run as root"
	echo
	echo "Run as Ceph User: $(ls /home | grep -i ceph)"
	exit 1
fi

#useradd ceph_ansible
#echo "password" | passwd "ceph_ansible" --stdin

#cat << EOF >/etc/sudoers.d/ceph_ansible
#ceph_ansible ALL = (root) NOPASSWD:ALL
#EOF

#chmod 0440 /etc/sudoers.d/ceph_ansible

# non interactive, emptly pass ""
su -c "ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa" ceph_ansible

# get everyone talking for ansible
for i in admin mon osd2
  do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no -i /home/ceph_ansible/.ssh/id_rsa.pub ceph_ansible@"${i}"
done

yum -y install ceph-deploy
firewall-cmd --zone=public --add-port=6789/tcp --permanent
#Create a directory on your admin node node for maintaining the configuration files and keys that ceph-deploy generates for your cluster.
cd ~/ceph_ansible && mkdir my-cluster
cd ~/ceph_ansible/my-cluster && ceph-deploy new mon
#On your admin node from the directory you created for holding your configuration details, perform the following steps using ceph-deploy.
ceph-deploy new mon
ceph-deploy install admin mon osd2
ceph-deploy mon create-initial
#Add two OSDs. For fast setup, this quick start uses a directory rather than an entire disk per Ceph OSD Daemon. See ceph-deploy osd for details on using separate disks/partitions for OSDs and journals. Login to the Ceph Nodes and create a directory for the Ceph OSD Daemon.
ssh mon mkdir -p /var/local/osd1
ssh osd2 mkdir -p /var/local/osd2
ceph-deploy osd prepare mon:/var/local/osd1 osd2:/var/local/osd2
ceph-deploy osd activate mon:/var/local/osd1 osd2:/var/local/osd2
#Use ceph-deploy to copy the configuration file and admin key to your admin node and your Ceph Nodes so that you can use the ceph CLI without having to specify the monitor address and ceph.client.admin.keyring each time you execute a command.
ceph-deploy admin admin mon osd2

#Ensure that you have the correct permissions for the ceph.client.admin.keyring.
chmod +r /etc/ceph/ceph.client.admin.keyring
ceph health

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
