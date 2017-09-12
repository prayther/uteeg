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

#check to make sure all machines are ready
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org gfs-node1.prayther.org gfs-backup.prayther.org
          do ssh "${i}" exit || echo "ssh to ${i} failded" || exit 1
done

for i in gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" rpm -qa | grep targetcli || ssh "${i}" yum -y install iscsi-initiator-utils targetcli || echo "yum -y install iscsi-initiator-utils targetcli failed" || exit 1 && \
	  ssh "${i}" firewall-cmd --zone=public --add-port=3260/tcp --permanent
	  ssh "${i}" firewall-cmd --reload
done

#could use an lv instead of the block device
#for i in gfs-node2.prayther.org gfs-node3.prayther.org
#  do ssh "${i}" lvcreate -L 2G -T rhs_vg/iscsi_pool
#	  ssh "${i}" lvcreate -V 1G -T rhs_vg/iscsi_pool -n iscsi_lv
#done

#create a 140M block device and configure an iscsi lun
for i in gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh ${i} "targetcli clearconfig confirm=True"
          ssh ${i} "targetcli backstores/fileio create disk1 /disk1.img 140M"
          ssh ${i} "targetcli ls iscsi 1 | grep iqn || targetcli /iscsi create iqn.2017-09.org.prayther:lun1"
          ssh ${i} "targetcli ls /iscsi 1 | grep iqn | cut -d\" \" -f4 > /tmp/wwn"
          scp ${i}:/tmp/wwn /tmp/wwn.${i}
          #scp ${i}:/etc/iscsi/initiatorname.iscsi /tmp/initiator.${i}
          #source /tmp/initiator.${i}
          #ssh ${i} "targetcli /iscsi/$(cat /tmp/wwn.${i})/tpg1/acls create ${InitiatorName}:clientlun1"
          ssh ${i} "targetcli /iscsi/$(cat /tmp/wwn.${i})/tpg1/acls create iqn.2017-09.org.prayther:clientlun1"
          ssh ${i} "targetcli /iscsi/$(cat /tmp/wwn.${i})/tpg1/luns create /backstores/fileio/disk1"
          ssh ${i} "targetcli saveconfig"
          ssh ${i} "systemctl enable target"
          ssh ${i} "systemctl restart target"
done

  #ssh "${i}" targetcli /iscsi/iqn.2003-01.org.linux-iscsi.gfs-node2.x8664:sn.a6c957b7f1c4/tpg1/luns create /backstores/fileio/disk1

#create volume using iscsi targets
#gluster volume create iscsivol \
#	gfs-node2.prayther.org \

ssh gfs-node1.prayther.org "rpm -qa | grep iscsi-initiator-utils || yum install -y iscsi-initiator-utils"
ssh gfs-node1.prayther.org "systemctl enable iscsi"
#ssh gfs-node1.prayther.org "systemctl restart iscsid"

ssh gfs-node1.prayther.org "cat << EOF > /etc/iscsi/initiatorname.iscsi
InitiatorName=iqn.2017-09.org.prayther:clientlun1
EOF"
ssh gfs-node1.prayther.org "systemctl restart iscsid"

ssh gfs-node1.prayther.org "iscsiadm --mode discoverydb --type sendtargets --portal gfs-node2.prayther.org --discover"
ssh gfs-node1.prayther.org "iscsiadm --mode node --targetname iqn.2017-09.org.prayther:lun1 --portal gfs-node2.prayther.org --login"

ssh gfs-node1.prayther.org "systemctl restart iscsi"
ssh gfs-node1.prayther.org "iscsiadm --mode node --targetname iqn.2017-09.org.prayther:lun1 --portal gfs-node2.prayther.org --login"
ssh gfs-node1.prayther.org "systemctl status iscsi"
ssh gfs-node1.prayther.org "lsblk --scsi"

#if you run the script twice
ssh gfs-node1.prayther.org "umount /mnt/iscsi*"
#delele partition with fdisk
ssh gfs-node1.prayther.org "echo 'd

w'|fdisk /dev/sda"
ssh gfs-node1.prayther.org "partprobe"
#delele partition with fdisk
ssh gfs-node1.prayther.org "echo 'd

w'|fdisk /dev/sda"
ssh gfs-node1.prayther.org "partprobe"
#create 10M primary partition
ssh gfs-node1.prayther.org "echo 'n



+10M
w'|fdisk /dev/sda"
ssh gfs-node1.prayther.org "partprobe"
#create 100M primary partition. xfs requires larger partition
ssh gfs-node1.prayther.org "echo 'n



+100M
w'|fdisk /dev/sda"
#partprobe to recognize changes
ssh gfs-node1.prayther.org "partprobe"
ssh gfs-node1.prayther.org "mkfs.ext4 /dev/sda1"
ssh gfs-node1.prayther.org "e2label /dev/sda1 iscsilun0"
ssh gfs-node1.prayther.org "e2label /dev/sda1"
ssh gfs-node1.prayther.org "iscsiadm -m session -P 3"
ssh gfs-node1.prayther.org "mkdir -pv /mnt/iscsiext4"
ssh gfs-node1.prayther.org "mount -L iscsilun0 /mnt/iscsiext4"
ssh gfs-node1.prayther.org "touch /mnt/iscsiext4/me"
#mount with label on xfs partiton
ssh gfs-node1.prayther.org "mkfs.xfs -f -b size=1024 /dev/sda2"
ssh gfs-node1.prayther.org "xfs_admin -L "newlabel" /dev/sda2"
ssh gfs-node1.prayther.org "mkdir -pv /mnt/iscsixfs"
ssh gfs-node1.prayther.org "mount -L iscsilun0 /mnt/iscsixfs"
ssh gfs-node1.prayther.org "touch /mnt/iscsixfs/me"

#make bricks for tier
ssh gfs-node1.prayther.org "mkdir -pv /mnt/iscsiext4/brk1"
ssh gfs-node1.prayther.org "mkdir -pv /mnt/iscsixfs/brk2"

gluster volume tier labvol attach replica 2 \
	gfs-node1.prayther.org:/mnt/iscsiext4/brk1 \
	gfs-node1.prayther.org:/mnt/iscsixfs/brk2
#status
gluster volume info labvol
gluster volume tier labvol status

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
