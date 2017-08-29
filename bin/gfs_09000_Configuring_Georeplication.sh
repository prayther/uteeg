#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
cd "${BASH_SOURCE%/*}"

logfile="../log/$(basename $0 .sh).log
donefile="../log/$(basename $0 .sh).done
touch $logfile
touch $donefile

exec > >(tee -a "$logfile") 2>&1

echo "###INFO: Starting $0
echo "###INFO: $(date)

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

#########################################################################################

#make sure only to do the following once. or keys will change
# admin node: non interactive, emptly pass "
#if [[ $(hostname -s | awk -F"_" '{print $2}') -eq "admin" ]];then
#        ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
#        ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
#fi

#geouser for unpriv geo user.
ssh gfs-backup.prayther.org adduser geouser
ssh gfs-backup.prayther.org "echo password | passwd geouser --stdin"
ssh gfs-backup.prayther.org groupadd geogroup
ssh gfs-backup.prayther.org "usermod -G geogroup geouser"

# from gfs-admin get everyone talking
if [[ $(hostname -s | awk -F"-" '{print $2}') -eq "admin" ]];then
        for i in gfs-backup.prayther.org
          do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no geouser@"${i}" && \
		  sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${i}"
        done
fi

#firewall for glusterfs
for i in gfs-backup.prayther.org
  do ssh "${i}" firewall-cmd --zone=public --add-service=glusterfs --permanent && \
          ssh "${i}" firewall-cmd --add-service=rpc-bind --add-service=nfs --permanent && \
          ssh "${i}" systemctl restart firewalld
done

# VG, Thin pool, LV virtualsize
ssh gfs-backup.prayther.org "vgcreate backupvol_vg /dev/vdb"
ssh gfs-backup.prayther.org "lvcreate -L 10G -T backupvol_vg/backupvol_pool"
#LV virtualsize
ssh gfs-backup.prayther.org "lvcreate -V 6G -T backupvol_vg/backupvol_pool -n backup_lv1"
#mkfs
ssh gfs-backup.prayther.org "mkfs.xfs -f -i size=512 /dev/backupvol_vg/backup_lv1"
#mount dir
ssh gfs-backup.prayther.org "ls /bricks/backup_lv1 || mkdir -pv /bricks/backup_lv1"
#fstab entry
ssh gfs-backup.prayther.org "grep backup_lv1 /etc/fstab || echo /dev/backupvol_vg/backup_lv1 /bricks/backup_lv1 xfs defaults 1 2 >> /etc/fstab"
#mount
ssh gfs-backup.prayther.org "mkdir -pv /bricks/backup_lv1"
ssh gfs-backup.prayther.org "mount /bricks/backup_lv1"
#mkdir selinux context
ssh gfs-backup.prayther.org "ls /bricks/backup_lv1/brick || mkdir -pv /bricks/backup_lv1/brick"
#semanage
ssh gfs-backup.prayther.org "semanage fcontext -a -t glusterd_brick_t /bricks/backup_lv1/brick"
#restorecon
ssh gfs-backup.prayther.org "restorecon -Rv /bricks/backup_lv1"
#create/start gluster volume: backupvol
ssh gfs-backup.prayther.org "gluster volume create backupvol \
        gfs-backup.prayther.org:/bricks/backup_lv1/brick force"
ssh gfs-backup.prayther.org "gluster volume start backupvol"
ssh gfs-backup.prayther.org "gluster volume status backupvol"

#Enable shared storage:
gluster volume set all cluster.enable-shared-storage enable
#/var/mountbroker-root. This directory must be created with permissions 0711
ssh gfs-backup.prayther.org "mkdir -pv -m 0711 /var/mountbroker-root"
ssh gfs-backup.prayther.org "semanage fcontext -a -e /home /var/mountbroker-root"
ssh gfs-backup.prayther.org "restorecon -Rv /var/mountbroker-root"
#Set the mountbroker-root directory to /var/mountbroker-root.
ssh gfs-backup.prayther.org "gluster system:: execute mountbroker \
	opt mountbroker-root /var/mountbroker-root"
#Set the mountbroker user for the backupvol volume to geouser.
ssh gfs-backup.prayther.org "gluster system:: execute mountbroker \
	user geouser backupvol"
#Set the geo-replication-log-group group to geogroup.
ssh gfs-backup.prayther.org "gluster system:: execute mountbroker \
 opt geo-replication-log-group geogroup"
#Allow RPC connections from unprivileged ports.
ssh gfs-backup.prayther.org "gluster system:: execute mountbroker \
	opt rpc-auth-allow-insecure on"

ssh gfs-backup.prayther.org "systemctl restart glusterd"

#create SSH key pairs for the georeplication daemon for each node.
gluster system:: execute gsec_create
#create and push the SSH keys that will be used for georeplication.
gluster volume geo-replication labvol \
	geouser@gfs-backup.prayther.org::backupvol create push-pem

#copy the keys pushed in the previous step to the correct locations.
ssh gfs-backup.prayther.org "/usr/libexec/glusterfs/set_geo_rep_pem_keys.sh \
	geouser labvol backupvol"

#configure the georeplication link between labvol and backupvol to use shared storage for keeping track of changes, and more.
gluster volume geo-replication labvol \
	geouser@gfs-backup.prayther.org::backupvol config use_meta_volume true
#Start georeplication between labvol and backupvol.
gluster volume geo-replication labvol \
	geouser@gfs-backup.prayther.org::backupvol start

#gluster volume geo-replication labvol \
#        geouser@gfs-backup.prayther.org::backupvol stop

gluster volume geo-replication status
# log file for trouble shooting
gluster volume geo-replication labvol geouser@gfs-backup.prayther.org::backupvol config log-file
#/var/log/glusterfs/geo-replication/labvol/ssh%3A%2F%2Fgeouser%40gfs-backup.prayther.org%3Agluster%3A%2F%2F127.0.0.1%3Abackupvol.log
gluster volume geo-replication labvol \
 geouser@gfs-backup.prayther.org::backupvol config checkpoint now
#geo-replication config updated successfully


#set the changelog.rollover-time setting for datavol to five seconds.
gluster volume set labvol changelog.rollover-time 5

#Configure the georeplication agreement to keep files deleted from labvol on backupvol.
gluster volume geo-replication labvol \
	geouser@gfs-backup.prayther.org::backupvol config ignore-deletes true

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
