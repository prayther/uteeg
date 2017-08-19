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
for i in gfs_admin gfs_node1 gfs_node2 gfs_node3
  do ssh "${i}" pvcreate /dev/vdb && \
          ssh "${i}" vgcreate rhs_vg /dev/vdb && \
          ssh "${i}" lvcreate -L 19G -T rhs_vg/rhs_pool
done
#LV virtualsize
ssh gfs_node1 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv4"
ssh gfs_node2 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv5"
ssh gfs_node3 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv6"
#mkfs
ssh gfs_node1 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv4"
ssh gfs_node2 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv5"
ssh gfs_node3 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv6"
#mount dir
ssh gfs_node1 "ls /bricks/rhs_lv4 || mkdir -p /bricks/rhs_lv4"
ssh gfs_node2 "ls /bricks/rhs_lv5 || mkdir -p /bricks/rhs_lv5"
ssh gfs_node3 "ls /bricks/rhs_lv6 || mkdir -p /bricks/rhs_lv6"
#fstab entry
ssh gfs_node1 "grep rhs_lv4 /etc/fstab || echo /dev/rhs_vg/rhs_lv4 /bricks/rhs_lv4 xfs defaults 1 2 >> /etc/fstab"
ssh gfs_node2 "grep rhs_lv5 /etc/fstab || echo /dev/rhs_vg/rhs_lv5 /bricks/rhs_lv5 xfs defaults 1 2 >> /etc/fstab"
ssh gfs_node3 "grep rhs_lv6 /etc/fstab || echo /dev/rhs_vg/rhs_lv6 /bricks/rhs_lv6 xfs defaults 1 2 >> /etc/fstab"
#mount
ssh gfs_node1 "mount /bricks/rhs_lv4"
ssh gfs_node2 "mount /bricks/rhs_lv5"
ssh gfs_node3 "mount /bricks/rhs_lv6"
#mkdir selinux context
ssh gfs_node1 "ls /bricks/rhs_lv4/brick || mkdir -p /bricks/rhs_lv4/brick"
ssh gfs_node2 "ls /bricks/rhs_lv5/brick || mkdir -p /bricks/rhs_lv5/brick"
ssh gfs_node3 "ls /bricks/rhs_lv6/brick || mkdir -p /bricks/rhs_lv6/brick"
#semanage
ssh gfs_node1 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv4/brick"
ssh gfs_node2 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv5/brick"
ssh gfs_node3 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv6/brick"
#restorecon
ssh gfs_node1 "restorecon -Rv /bricks/rhs_lv4"
ssh gfs_node2 "restorecon -Rv /bricks/rhs_lv5"
ssh gfs_node3 "restorecon -Rv /bricks/rhs_lv6"

#create/start gluster volume: labvol
#gluster volume create labvol \
#	10.0.0.10:/bricks/rhs_lv4/brick \
#	10.0.0.11:/bricks/rhs_lv5/brick \
#	10.0.0.12:/bricks/rhs_lv6/brick 
#gluster volume start labvol

#Add the 3 new bricks to the labvol volume, and set the replica count to two.
gluster volume add-brick labvol replica 2 \
	gfs_node1:/bricks/rhs_lv4/brick
	gfs_node2:/bricks/rhs_lv5/brick
	gfs_node3:/bricks/rhs_lv6/brick

gluster volume status labvol
gluster volume info labvol

echo "###INFO: Finished $0"
echo "###INFO: $(date)"