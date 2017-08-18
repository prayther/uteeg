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

if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
 echo ""
 echo "Need to run this on the 'admin' node"
 echo ""
 exit 1
fi

if [[ $(id -u) -eq "1" ]];then
	echo "Must run as root"
	echo
	exit 1
fi

# VG, Thin pool, LV virtualsize
#for i in gfs_node1 gfs_node2 gfs_node3
#  do ssh "${i}" pvcreate /dev/vdb
#          ssh "${i}" vgcreate rhs_vg /dev/vdb
#          ssh "${i}" lvcreate -L 10G -T rhs_vg/rhs_pool
#done
#for i in gfs_admin gfs_node1 gfs_node2 gfs_node3
#  do grep -F '[gluster]' /etc/ansible/hosts || echo "[gluster]" >> /etc/ansible/hosts && \
#	  grep "${i}" /etc/ansible/hosts || echo "${i}" >> /etc/ansible/hosts
#  done
for i in 10.0.0.9 10.0.0.10 10.0.0.11 10.0.0.12
  do ssh "${i}" firewall-cmd --zone=public --add-service=rpc-bind --add-service=nfs --permanent && \
          ssh "${i}" systemctl restart firewalld
done

gluster volume set labvol nfs.disable on
gluster volume set labvol auth.allow 10.0.0.0

gluster volume stop labvol
gluster volume start labvol


#if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "client" ]];then
ssh gfs_client	yum -y install glusterfs-fuse
#fi



echo "###INFO: Finished $0"
echo "###INFO: $(date)"
