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

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "gfs" ]];then
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

# VG, Thin pool, LV virtualsize
for i in gfs-admin gfs-node1 gfs-node2 gfs-node3
  do ssh "${i}" pvcreate /dev/vdb && \
          ssh "${i}" vgcreate rhs_vg /dev/vdb && \
          ssh "${i}" lvcreate -L 19G -T rhs_vg/rhs_pool
done
#LV virtualsize
ssh gfs-node1 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv1"
ssh gfs-node2 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv2"
ssh gfs-node3 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv3"
#mkfs
ssh gfs-node1 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv1"
ssh gfs-node2 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv2"
ssh gfs-node3 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv3"
#mount dir
ssh gfs-node1 "ls /bricks/rhs_lv1 || mkdir -p /bricks/rhs_lv1"
ssh gfs-node2 "ls /bricks/rhs_lv2 || mkdir -p /bricks/rhs_lv2"
ssh gfs-node3 "ls /bricks/rhs_lv3 || mkdir -p /bricks/rhs_lv3"
#fstab entry
ssh gfs-node1 "grep rhs_lv1 /etc/fstab || echo /dev/rhs_vg/rhs_lv1 /bricks/rhs_lv1 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node2 "grep rhs_lv2 /etc/fstab || echo /dev/rhs_vg/rhs_lv2 /bricks/rhs_lv2 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node3 "grep rhs_lv3 /etc/fstab || echo /dev/rhs_vg/rhs_lv3 /bricks/rhs_lv3 xfs defaults 1 2 >> /etc/fstab"
#mount
ssh gfs-node1 "mount /bricks/rhs_lv1"
ssh gfs-node2 "mount /bricks/rhs_lv2"
ssh gfs-node3 "mount /bricks/rhs_lv3"
#mkdir selinux context
ssh gfs-node1 "ls /bricks/rhs_lv1/brick || mkdir -p /bricks/rhs_lv1/brick"
ssh gfs-node2 "ls /bricks/rhs_lv2/brick || mkdir -p /bricks/rhs_lv2/brick"
ssh gfs-node3 "ls /bricks/rhs_lv3/brick || mkdir -p /bricks/rhs_lv3/brick"
#semanage
ssh gfs-node1 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv1/brick"
ssh gfs-node2 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv2/brick"
ssh gfs-node3 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv3/brick"
#restorecon
ssh gfs-node1 "restorecon -Rv /bricks/rhs_lv1"
ssh gfs-node2 "restorecon -Rv /bricks/rhs_lv2"
ssh gfs-node3 "restorecon -Rv /bricks/rhs_lv3"
#create/start gluster volume: labvol
gluster volume create labvol \
	10.0.0.10:/bricks/rhs_lv1/brick \
	10.0.0.11:/bricks/rhs_lv2/brick \
	10.0.0.12:/bricks/rhs_lv3/brick force
gluster volume start labvol
gluster volume status labvol

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
