#!/bin/bash -x

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

if [[ $(id -u) -eq "1" ]];then
	echo "Must run as root"
	echo
	exit 1
fi

#Install this on gfs nodes: gfs_admin gfs_node1 gfs_node2 gfs_node3

yum -y install redhat-storage-server glusterfs-ganesha gstatus sshpass
systemctl enable glusterd
systemctl start glusterd
firewall-cmd --zone=public --add-service=glusterfs --permanent

# non interactive, emptly pass ""
#su -c "ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa" ceph_ansible
ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa

# from gfs_admin get everyone talking 
for i in gfs_node1 gfs_node2 gfs_node3
  do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${i}"
done


echo "###INFO: Finished $0"
echo "###INFO: $(date)"
