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

#runs or not based on hostname; ceph-?? gfs-??? s.prayther.orgat-???
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
#for i in gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
#  do ssh "${i}" pvcreate /dev/vdb
#          ssh "${i}" vgcreate rhs_vg /dev/vdb
#          ssh "${i}" lvcreate -L 10G -T rhs_vg/rhs_pool
#done
#for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
#  do grep -F '[gluster]' /etc/ansible/hosts || echo "[gluster]" >> /etc/ansible/hosts && \
#	  grep "${i}" /etc/ansible/hosts || echo "${i}" >> /etc/ansible/hosts
#  done

#allow NFS traffic through the firewall.
#for i in 10.0.0.9 10.0.0.10 10.0.0.11 10.0.0.12
#  do ssh "${i}" firewall-cmd --zone=public --add-service=rpc-bind --add-service=nfs --permanent && \
#          ssh "${i}" systemctl restart firewalld
#done

## admin node: non interactive, emptly pass ""
#if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
#        ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
#        ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
#fi
## from gfs-admin.prayther.org get everyone talking
#if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
#        for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
#          do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${i}"

#apply all relevant volume options
gluster volume set labvol nfs.disable on
gluster volume set labvol auth.allow '10.0.0.*'

echo y | gluster volume stop labvol
gluster volume start labvol

#configure all relevant options
gluster volume set distdispvol nfs.disable off
gluster volume set distdispvol nfs.rpc-auth-allow '10.0.0.*'
gluster volume set distdispvol nfs.rpc-auth-reject 172.25.250.254

echo y | gluster volume stop distdispvol
gluster volume start distdispvol

#Configure client to persistently mount
#mount native client
ssh rhel-client.prayther.org yum -y install glusterfs-fuse
ssh rhel-client.prayther.org "echo #gfs-node1.prayther.org:/labvol /mnt/labvol glusterfs _netdev,acl 0 0 >> /etc/fstab"
ssh rhel-client.prayther.org "mkdir -pv /mnt/labvol/games"
ssh rhel-client.prayther.org "mkdir -pv /mnt/labvol/private_games"
doit ssh rhel-client.prayther.org "mount -t glusterfs gfs-node1:/labvol /mnt/labvol"
#mount nfs
ssh rhel-client.prayther.org "mkdir -pv /mnt/distdispvol"
ssh rhel-client.prayther.org "echo #gfs-node2.prayther.org:/distdispvol /mnt/distdispvol nfs rw 0 0 >> /etc/fstab"
doit ssh rhel-client.prayther.org "mount -t glusterfs gfs-node2:/distdispvol /mnt/distdispvol"

#ownership, facl's
ssh rhel-client.prayther.org "chgrp games /mnt/labvol/games"
ssh rhel-client.prayther.org "chmod 2770 /mnt/labvol/games"
ssh rhel-client.prayther.org "touch /mnt/labvol/games/me"
ssh rhel-client.prayther.org "touch /mnt/labvol/private_games/me"
#group full access to any existing files and directories
ssh rhel-client.prayther.org "setfacl -R -m g:games:rwX /mnt/labvol/games"
#group full access to any new files and directories
ssh rhel-client.prayther.org "setfacl -R -m d:g:games:rwX /mnt/labvol/games"


#group read-only access to any existing files and directories
ssh rhel-client.prayther.org "setfacl -R -m g:games:rX /mnt/labvol/private_games"
#group read-only access to any new files and directories
ssh rhel-client.prayther.org "setfacl -R -m d:g:games:rX /mnt/labvol/private_games"

#[root@rhel-client.prayther.org games]# ll -Z /mnt/labvol/
#drwxrws---+ root games system_u:object_r:fusefs_t:s0    games
#[root@rhel-client.prayther.org games]# getfacl /mnt/labvol/games
#getfacl: Removing leading '/' from absolute path names
# file: mnt/labvol/games
# owner: root
# group: games
# flags: -s-
#user::rwx
#group::rwx
#group:games:rwx
#mask::rwx
#other::---
#default:user::rwx
#default:group::rwx
#default:group:games:rwx
#default:mask::rwx
#default:other::---

#[root@rhel-client.prayther.org games]# getfacl /mnt/labvol/private_games
#getfacl: Removing leading '/' from absolute path names
# file: mnt/labvol/private_games
# owner: root
# group: root
#user::rwx
#group::r-x
#group:games:r-x
#mask::r-x
#other::r-x
#default:user::rwx
#default:group::r-x
#default:group:games:r-x
#default:mask::r-x
#default:other::r-x

#Enable quotas for the 'labvol' volume, and set the hard and soft limits (1 GiB and 85%) for the /games directory.
ssh rhel-client.prayther.org "umount /mnt/labvol"
gluster volume quota labvol enable
gluster volume quota labvol limit-usage /games 1GB 85%
#the df command will report the hard-limit as the available space on a directory.
gluster volume set labvol quota-deem-statfs on

#Set the quota update timeout for 'labvol' before the soft limit is reached to 30 seconds, and to five seconds for when the soft limit is exceeded.
gluster volume quota labvol soft-timeout 30s
gluster volume quota labvol hard-timeout 5s
doit ssh rhel-client.prayther.org "mount -t glusterfs gfs-node1:/labvol /mnt/labvol"

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
