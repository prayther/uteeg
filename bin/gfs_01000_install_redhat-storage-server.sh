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

#for i in gfs_admin gfs_node1 gfs_node2 gfs_node3
#  do ssh "${i}" yum -y install ansible gdeploy redhat-storage-server glusterfs-ganesha gstatus sshpass ntpdate nagios-server-addons glusterfs glusterfs-fuse heketi-client heketi ctdb krb5-workstation ntpdate nfs-utils rpcbind cifs-utils samba samba-client samba-winbind samba-winbind-clients samba-winbind-krb5-locator
#done
# yum groupinstall "Infiniband Support"

#systemctl enable glusterd
#systemctl start glusterd
#firewall-cmd --get-active-zones
#firewall-cmd --zone=public --add-service=glusterfs --permanent
#systemctl restart firewalld

#tuned-adm list
#tuned-adm profile rhgs-random-io

# admin node: non interactive, emptly pass ""
if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
        ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
        ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
fi

# from gfs_admin get everyone talking 
if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
        for i in gfs_admin gfs_node1 gfs_node2 gfs_node3
          do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${i}"
        done
fi

for i in gfs_admin gfs_node1 gfs_node2 gfs_node3
  do ssh "${i}" yum -y install ansible gdeploy redhat-storage-server glusterfs-ganesha gstatus sshpass ntpdate nagios-server-addons glusterfs glusterfs-fuse heketi-client heketi ctdb krb5-workstation ntpdate nfs-utils rpcbind cifs-utils samba samba-client samba-winbind samba-winbind-clients samba-winbind-krb5-locator
done


#only run this on admin node gfs_admin, ceph_admin
if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
        for i in gfs_node1 gfs_node2 gfs_node3
          do gluster peer probe "${i}"
        done
fi

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
