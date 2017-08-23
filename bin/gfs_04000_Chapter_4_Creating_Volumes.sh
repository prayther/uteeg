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
#for i in gfs-node1 gfs-node2 gfs-node3
#  do ssh "${i}" pvcreate /dev/vdb
#          ssh "${i}" vgcreate rhs_vg /dev/vdb
#          ssh "${i}" lvcreate -L 10G -T rhs_vg/rhs_pool
#done
for i in gfs-admin gfs-node1 gfs-node2 gfs-node3
  do grep -F '[gluster]' /etc/ansible/hosts || echo "[gluster]" >> /etc/ansible/hosts && \
	  grep "${i}" /etc/ansible/hosts || echo "${i}" >> /etc/ansible/hosts
  done

#LV virtualsize
ansible gfs-admin -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-11"
ansible gfs-admin -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-12"
ansible gfs-admin -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-13"
ansible gfs-admin -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-14"
#ssh gfs-admin for i in {1..4}; do lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-1${i};done
ansible gfs-node1 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-21"
ansible gfs-node1 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-22"
ansible gfs-node1 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-23"
ansible gfs-node1 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-24"
#ssh gfs-node1 for i in {1..4}; do lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-2${i};done
ansible gfs-node2 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-31"
ansible gfs-node2 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-32"
ansible gfs-node2 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-33"
ansible gfs-node2 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-34"
#ssh gfs-node2 for i in {1..4}; do lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-3${i};done
ansible gfs-node3 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-41"
ansible gfs-node3 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-42"
ansible gfs-node3 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-43"
ansible gfs-node3 -a "lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-44"
#ssh gfs-node3 for i in {1..4}; do lvcreate -V 2G -T rhs_vg/rhs_pool -n brick-4${i};done
#mkfs
ansible gfs-admin -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-11"
ansible gfs-admin -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-12"
ansible gfs-admin -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-13"
ansible gfs-admin -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-14"
#ssh gfs-admin for i in {1..4}; do mkfs -t xfs -i size=512 /dev/rhs_vg/brick-1${i};done
ansible gfs-node1 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-21"
ansible gfs-node1 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-22"
ansible gfs-node1 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-23"
ansible gfs-node1 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-24"
#ssh gfs-node1 for i in {1..4}; do mkfs -t xfs -i size=512 /dev/rhs_vg/brick-2${i};done
ansible gfs-node2 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-31"
ansible gfs-node2 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-32"
ansible gfs-node2 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-33"
ansible gfs-node2 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-34"
#ssh gfs-node2 for i in {1..4}; do mkfs -t xfs -i size=512 /dev/rhs_vg/brick-3${i};done
ansible gfs-node3 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-41"
ansible gfs-node3 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-42"
ansible gfs-node3 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-43"
ansible gfs-node3 -a "mkfs -t xfs -i size=512 /dev/rhs_vg/brick-44"
#ssh gfs-node3 for i in {1..4}; do mkfs -t xfs -i size=512 /dev/rhs_vg/brick-4${i};done
#mount dir
#for i in {1..4}
#  do ssh gfs-admin mkdir -p /bricks/brick-1"${i}"
#done
for i in {1..4}
  do ssh gfs-node1 mkdir -p /bricks/brick-2"${i}"
done
for i in {1..4}
  do ssh gfs-node2 mkdir -p /bricks/brick-3"${i}"
done
for i in {1..4}
  do ssh gfs-node3 mkdir -p /bricks/brick-4"${i}"
done
#fstab entry
ssh gfs-admin "grep brick-1 /etc/fstab || echo /dev/rhs_vg/brick-11 /bricks/brick-11 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-admin "grep brick-1 /etc/fstab || echo /dev/rhs_vg/brick-12 /bricks/brick-12 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-admin "grep brick-1 /etc/fstab || echo /dev/rhs_vg/brick-13 /bricks/brick-13 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-admin "grep brick-1 /etc/fstab || echo /dev/rhs_vg/brick-14 /bricks/brick-14 xfs defaults 1 2 >> /etc/fstab"

ssh gfs-node1 "grep brick-2 /etc/fstab || echo /dev/rhs_vg/brick-21 /bricks/brick-21 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node1 "grep brick-2 /etc/fstab || echo /dev/rhs_vg/brick-22 /bricks/brick-22 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node1 "grep brick-2 /etc/fstab || echo /dev/rhs_vg/brick-23 /bricks/brick-23 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node1 "grep brick-2 /etc/fstab || echo /dev/rhs_vg/brick-24 /bricks/brick-24 xfs defaults 1 2 >> /etc/fstab"

ssh gfs-node2 "grep brick-3 /etc/fstab || echo /dev/rhs_vg/brick-31 /bricks/brick-31 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node2 "grep brick-3 /etc/fstab || echo /dev/rhs_vg/brick-32 /bricks/brick-32 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node2 "grep brick-3 /etc/fstab || echo /dev/rhs_vg/brick-33 /bricks/brick-33 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node2 "grep brick-3 /etc/fstab || echo /dev/rhs_vg/brick-34 /bricks/brick-34 xfs defaults 1 2 >> /etc/fstab"

ssh gfs-node3 "grep brick-4 /etc/fstab || echo /dev/rhs_vg/brick-41 /bricks/brick-41 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node3 "grep brick-4 /etc/fstab || echo /dev/rhs_vg/brick-42 /bricks/brick-42 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node3 "grep brick-4 /etc/fstab || echo /dev/rhs_vg/brick-43 /bricks/brick-43 xfs defaults 1 2 >> /etc/fstab"
ssh gfs-node3 "grep brick-4 /etc/fstab || echo /dev/rhs_vg/brick-44 /bricks/brick-44 xfs defaults 1 2 >> /etc/fstab"
#mount
ssh gfs-admin "mount -a"
ssh gfs-node1 "mount -a"
ssh gfs-node2 "mount -a"
ssh gfs-node3 "mount -a"
#mkdir selinux context
ssh gfs-admin "ls /bricks/brick-11/brick || mkdir -p /bricks/brick-11/brick"
ssh gfs-admin "ls /bricks/brick-12/brick || mkdir -p /bricks/brick-12/brick"
ssh gfs-admin "ls /bricks/brick-13/brick || mkdir -p /bricks/brick-13/brick"
ssh gfs-admin "ls /bricks/brick-14/brick || mkdir -p /bricks/brick-14/brick"

ssh gfs-node1 "ls /bricks/brick-21/brick || mkdir -p /bricks/brick-21/brick"
ssh gfs-node1 "ls /bricks/brick-22/brick || mkdir -p /bricks/brick-22/brick"
ssh gfs-node1 "ls /bricks/brick-23/brick || mkdir -p /bricks/brick-23/brick"
ssh gfs-node1 "ls /bricks/brick-24/brick || mkdir -p /bricks/brick-24/brick"

ssh gfs-node2 "ls /bricks/brick-31/brick || mkdir -p /bricks/brick-31/brick"
ssh gfs-node2 "ls /bricks/brick-32/brick || mkdir -p /bricks/brick-32/brick"
ssh gfs-node2 "ls /bricks/brick-33/brick || mkdir -p /bricks/brick-33/brick"
ssh gfs-node2 "ls /bricks/brick-34/brick || mkdir -p /bricks/brick-34/brick"

ssh gfs-node3 "ls /bricks/brick-41/brick || mkdir -p /bricks/brick-41/brick"
ssh gfs-node3 "ls /bricks/brick-42/brick || mkdir -p /bricks/brick-42/brick"
ssh gfs-node3 "ls /bricks/brick-43/brick || mkdir -p /bricks/brick-43/brick"
ssh gfs-node3 "ls /bricks/brick-44/brick || mkdir -p /bricks/brick-44/brick"
#semanage
ssh gfs-admin "semanage fcontext -a -t glusterd_brick_t /bricks/brick-11/brick"
ssh gfs-admin "semanage fcontext -a -t glusterd_brick_t /bricks/brick-12/brick"
ssh gfs-admin "semanage fcontext -a -t glusterd_brick_t /bricks/brick-13/brick"
ssh gfs-admin "semanage fcontext -a -t glusterd_brick_t /bricks/brick-14/brick"

ssh gfs-node1 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-21/brick"
ssh gfs-node1 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-22/brick"
ssh gfs-node1 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-23/brick"
ssh gfs-node1 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-24/brick"

ssh gfs-node2 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-31/brick"
ssh gfs-node2 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-32/brick"
ssh gfs-node2 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-33/brick"
ssh gfs-node2 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-34/brick"

ssh gfs-node3 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-41/brick"
ssh gfs-node3 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-42/brick"
ssh gfs-node3 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-43/brick"
ssh gfs-node3 "semanage fcontext -a -t glusterd_brick_t /bricks/brick-44/brick"
#restorecon
ssh gfs-admin "restorecon -Rv /bricks/brick-11"
ssh gfs-admin "restorecon -Rv /bricks/brick-12"
ssh gfs-admin "restorecon -Rv /bricks/brick-13"
ssh gfs-admin "restorecon -Rv /bricks/brick-14"

ssh gfs-node1 "restorecon -Rv /bricks/brick-21"
ssh gfs-node1 "restorecon -Rv /bricks/brick-22"
ssh gfs-node1 "restorecon -Rv /bricks/brick-23"
ssh gfs-node1 "restorecon -Rv /bricks/brick-24"

ssh gfs-node2 "restorecon -Rv /bricks/brick-31"
ssh gfs-node2 "restorecon -Rv /bricks/brick-32"
ssh gfs-node2 "restorecon -Rv /bricks/brick-33"
ssh gfs-node2 "restorecon -Rv /bricks/brick-34"

ssh gfs-node3 "restorecon -Rv /bricks/brick-41"
ssh gfs-node3 "restorecon -Rv /bricks/brick-42"
ssh gfs-node3 "restorecon -Rv /bricks/brick-43"
ssh gfs-node3 "restorecon -Rv /bricks/brick-44"
#Distributed-Replicated
gluster volume create distreplvol replica 2 \
	10.0.0.9:/bricks/brick-11/brick \
        10.0.0.10:/bricks/brick-21/brick \
        10.0.0.11:/bricks/brick-31/brick \
        10.0.0.12:/bricks/brick-41/brick force

#gluster volume create distreplvol replica 2 \
#	10.0.0.9:/bricks/brick-11/brick \
#	10.0.0.9:/bricks/brick-12/brick \
#	10.0.0.9:/bricks/brick-13/brick \
#	10.0.0.9:/bricks/brick-14/brick \
#	10.0.0.10:/bricks/brick-21/brick \
#	10.0.0.10:/bricks/brick-22/brick \
#	10.0.0.10:/bricks/brick-23/brick \
#	10.0.0.10:/bricks/brick-24/brick \
#	10.0.0.11:/bricks/brick-31/brick \
#	10.0.0.11:/bricks/brick-32/brick \
#	10.0.0.11:/bricks/brick-33/brick \
#	10.0.0.11:/bricks/brick-34/brick \
#	10.0.0.12:/bricks/brick-41/brick \
#	10.0.0.12:/bricks/brick-42/brick \
#	10.0.0.12:/bricks/brick-43/brick \
#	10.0.0.12:/bricks/brick-44/brick 
gluster volume start distreplvol
gluster volume status distreplvol
gluster volume info distreplvol
#gluster volume stop distreplvol
#gluster volume delete distreplvol
#Create and start the distdispvol volume as outlined.

#I had one extra machine so too many bricks for equation.
#probably remove gfs-admin from this file
rm -f /tmp/distdispbricks
#echo "10.0.0.9:/bricks/brick-11/brick" >> /tmp/distdispbricks
echo "10.0.0.9:/bricks/brick-12/brick" >> /tmp/distdispbricks
echo "10.0.0.9:/bricks/brick-13/brick" >> /tmp/distdispbricks
echo "10.0.0.9:/bricks/brick-14/brick" >> /tmp/distdispbricks
#echo "10.0.0.10:/bricks/brick-21/brick" >> /tmp/distdispbricks
echo "10.0.0.10:/bricks/brick-22/brick" >> /tmp/distdispbricks
echo "10.0.0.10:/bricks/brick-23/brick" >> /tmp/distdispbricks
echo "10.0.0.10:/bricks/brick-24/brick" >> /tmp/distdispbricks
#echo "10.0.0.11:/bricks/brick-31/brick" >> /tmp/distdispbricks
echo "10.0.0.11:/bricks/brick-32/brick" >> /tmp/distdispbricks
echo "10.0.0.11:/bricks/brick-33/brick" >> /tmp/distdispbricks
echo "10.0.0.11:/bricks/brick-34/brick" >> /tmp/distdispbricks
#echo "10.0.0.12:/bricks/brick-41/brick" >> /tmp/distdispbricks
echo "10.0.0.12:/bricks/brick-42/brick" >> /tmp/distdispbricks
echo "10.0.0.12:/bricks/brick-43/brick" >> /tmp/distdispbricks
echo "10.0.0.12:/bricks/brick-44/brick" >> /tmp/distdispbricks

#Distributed-Dispersed
gluster volume create distdispvol \
disperse-data 4 redundancy 2 $(</tmp/distdispbricks) force

gluster volume start distdispvol
gluster volume status distdispvol
echo "###INFO: Finished $0"
echo "###INFO: $(date)"
