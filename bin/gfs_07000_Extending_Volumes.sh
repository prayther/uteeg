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

######################################################################################################
#LV virtualsize
ssh gfs-node1 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv4"
ssh gfs-node2 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv5"
ssh gfs-node3 "lvcreate -V 2G -T rhs_vg/rhs_pool -n rhs_lv6"
#mkfs
ssh gfs-node1 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv4"
ssh gfs-node2 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv5"
ssh gfs-node3 "mkfs -t xfs -i size=512 /dev/rhs_vg/rhs_lv6"
#mount dir
ssh gfs-node1 "ls /bricks/rhs_lv4 || mkdir -p /bricks/rhs_lv4"
ssh gfs-node2 "ls /bricks/rhs_lv5 || mkdir -p /bricks/rhs_lv5"
ssh gfs-node3 "ls /bricks/rhs_lv6 || mkdir -p /bricks/rhs_lv6"
#fstab entry
ssh gfs-node1 "grep rhs_lv4 /etc/fstab || echo /dev/rhs_vg/rhs_lv4 /bricks/rhs_lv4 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node2 "grep rhs_lv5 /etc/fstab || echo /dev/rhs_vg/rhs_lv5 /bricks/rhs_lv5 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node3 "grep rhs_lv6 /etc/fstab || echo /dev/rhs_vg/rhs_lv6 /bricks/rhs_lv6 xfs defaults 1 2 >> /etc/fstab"
#mount
ssh gfs-node1 "mount /bricks/rhs_lv4"
ssh gfs-node2 "mount /bricks/rhs_lv5"
ssh gfs-node3 "mount /bricks/rhs_lv6"
#mkdir selinux context
ssh gfs-node1 "ls /bricks/rhs_lv4/brick || mkdir -p /bricks/rhs_lv4/brick"
ssh gfs-node2 "ls /bricks/rhs_lv5/brick || mkdir -p /bricks/rhs_lv5/brick"
ssh gfs-node3 "ls /bricks/rhs_lv6/brick || mkdir -p /bricks/rhs_lv6/brick"
#semanage
ssh gfs-node1 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv4/brick"
ssh gfs-node2 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv5/brick"
ssh gfs-node3 "semanage fcontext -a -t glusterd_brick_t /bricks/rhs_lv6/brick"
#restorecon
ssh gfs-node1 "restorecon -Rv /bricks/rhs_lv4"
ssh gfs-node2 "restorecon -Rv /bricks/rhs_lv5"
ssh gfs-node3 "restorecon -Rv /bricks/rhs_lv6"

#create/start gluster volume: labvol
#gluster volume create labvol \
#	10.0.0.10:/bricks/rhs_lv4/brick \
#	10.0.0.11:/bricks/rhs_lv5/brick \
#	10.0.0.12:/bricks/rhs_lv6/brick 
#gluster volume start labvol

#Add the 3 new bricks to the labvol volume, and set the replica count to two.
gluster volume add-brick labvol replica 2 \
	10.0.0.10:/bricks/rhs_lv4/brick \
	10.0.0.11:/bricks/rhs_lv5/brick \
	10.0.0.12:/bricks/rhs_lv6/brick
#Rebalance operations can negatively impact performance on a volume.
#lazy When set to lazy every node is only allowed to migrate one file at a time.
#normal This is the default setting. This allows every node to migrate two files at once, or (NUMBER-OF-LOGICAL_CPUS - 4 ) / 2, whichever is greater. 
#aggressive This allows every node to migrate four files at once, or (NUMBER-OF-LOGICAL_CPUS - 4 ) / 2, whichever is greater. 
gluster volume set labvol cluster.rebal-throttle aggressive
gluster volume rebalance labvol start
gluster volume rebalance labvol status

gluster volume status labvol
gluster volume info labvol
gluster volume rebalance labvol start
gluster volume rebalance labvol status

#Red Hat Gluster Storage volumes can be shrunk while online by removing one or more bricks. During removal, the replica count can be adjusted as well.
gluster volume remove-brick labvol gfs-node1:/bricks/rhs_lv4/brick gfs-node1:/bricks/rhs_lv1/brick start
gluster volume remove-brick labvol gfs-node1:/bricks/rhs_lv4/brick gfs-node1:/bricks/rhs_lv1/brick status
echo y | gluster volume remove-brick labvol gfs-node1:/bricks/rhs_lv4/brick gfs-node1:/bricks/rhs_lv1/brick commit 

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
