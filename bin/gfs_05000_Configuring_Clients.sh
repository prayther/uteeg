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

#allow NFS traffic through the firewall.
for i in 10.0.0.9 10.0.0.10 10.0.0.11 10.0.0.12
  do ssh "${i}" firewall-cmd --zone=public --add-service=rpc-bind --add-service=nfs --permanent && \
          ssh "${i}" systemctl restart firewalld
done

## admin node: non interactive, emptly pass ""
#if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
#        ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
#        ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
#fi
## from gfs_admin get everyone talking
#if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
#        for i in gfs_admin gfs_node1 gfs_node2 gfs_node3
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
ssh gfs_client yum -y install glusterfs-fuse
ssh gfs_client mkdir -p /mnt/labvol/games
ssh gfs_client mkdir -p /mnt/labvol/private_games
ssh gfs_client "echo gfs_node1:/labvol /mnt/labvol glusterfs _netdev,acl 0 0 >> /etc/fstab"
ssh gfs_client "mount -a"
#mount nfs
ssh gfs_client mkdir /mnt/distdispvol
ssh gfs_client "echo gfs_node2:/distdispvol /mnt/distdispvol nfs rw 0 0 >> /etc/fstab"
ssh gfs_client "mount -a"

#ownership, facl's
ssh gfs_client chgrp games /mnt/labvol/games
ssh gfs_client chmod 2770 /mnt/labvol/games
ssh gfs_client "touch /mnt/labvol/games/me"
ssh gfs_client "touch /mnt/labvol/private_games/me"
#group full access to any existing files and directories
ssh gfs_client "setfacl -R -m g:games:rwX /mnt/labvol/games"
#group full access to any new files and directories
ssh gfs_client "setfacl -R -m d:g:games:rwX /mnt/labvol/games"


#group read-only access to any existing files and directories
ssh gfs_client "setfacl -R -m g:games:rX /mnt/labvol/private_games"
#group read-only access to any new files and directories
ssh gfs_client "setfacl -R -m d:g:games:rX /mnt/labvol/private_games"

#[root@gfs_client games]# ll -Z /mnt/labvol/
#drwxrws---+ root games system_u:object_r:fusefs_t:s0    games
#[root@gfs_client games]# getfacl /mnt/labvol/games
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

#[root@gfs_client games]# getfacl /mnt/labvol/private_games
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
ssh gfs_client "umount /mnt/labvol"
gluster volume quota labvol enable
gluster volume quota labvol limit-usage /games 1GB 85%
#the df command will report the hard-limit as the available space on a directory.
gluster volume set labvol quota-deem-statfs on

#Set the quota update timeout for 'labvol' before the soft limit is reached to 30 seconds, and to five seconds for when the soft limit is exceeded.
gluster volume quota labvol soft-timeout 30s
gluster volume quota labvol hard-timeout 5s
ssh gfs_client "mount /mnt/labvol"

echo "###INFO: Finished $0"
echo "###INFO: $(date)"