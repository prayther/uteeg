##!/bin/bash -x
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "systemctl status firewalld"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "setenforce permissive"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "systemctl stop firewalld"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "systemctl disable firewalld"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "pvcreate /dev/vda3"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "lvcreate -L 1G -T rhs_vg/lv"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "lvcreate -V 1G -T rhs_vg/lv -n lv$i"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mkfs.xfs -f -i size=512  /dev/rhs_vg/lv$i"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mkdir -pv /mnt/lv$i"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "sed -i /lv$i/d /etc/fstab"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "echo /dev/rhs_vg/lv$i /mnt/lv$i xfs defaults 0 0 >> /etc/fstab"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mount -a && mount | grep lv$i"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "gluster peer probe gfs-node$i.prayther.org"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mkdir -pv /mnt/lv$i/brk$i"
#done


#gluster volume create vol gfs-node1.prayther.org:/mnt/lv1/brk1 gfs-node2.prayther.org:/mnt/lv2/brk2 gfs-node3.prayther.org:/mnt/lv3/brk2
#gluster volume start vol
#gluster volume status vol

#gluster volume stop vol
#gluster volume status vol
#gluster volume delete vol
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "umount /mnt/lv*"
#done

#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mkfs.xfs -f -i size=512  /dev/rhs_vg/lv$i"
#done

#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mount -a"
#done

#for i in {1..3}
#do ssh gfs-node$i.prayther.org "systemctl restart glusterd && sleep 5"
#done

#gluster volume create vol replica 2 gfs-node1.prayther.org:/mnt/lv1/brk1 gfs-node2.prayther.org:/mnt/lv2/brk2

#gluster volume remove-brick vol gfs-node1.prayther.org:/mnt/lv1/brk1 gfs-node2.prayther.org:/mnt/lv2/brk2 start
#gluster volume remove-brick vol gfs-node1.prayther.org:/mnt/lv1/brk1 gfs-node2.prayther.org:/mnt/lv2/brk2 status
#gluster volume remove-brick vol gfs-node1.prayther.org:/mnt/lv1/brk1 gfs-node2.prayther.org:/mnt/lv2/brk2 commit

#gluster volume stop vol
#gluster volume status vol
#gluster volume delete vol

#for i in {1..3}
#do ssh gfs-node$i.prayther.org "umount /mnt/lv*"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mkfs.xfs -f -i size=512  /dev/rhs_vg/lv$i"
#done
#
#for i in {1..3}
#do ssh gfs-node$i.prayther.org "mount -a && mount | grep lv$i"
#done
#
#for i in {1..3};do ssh gfs-node$i.prayther.org "systemctl restart glusterd && sleep 5 && systemctl status glusterd";done

#geo-replication
#gluster system:: execute gsec_create
#
#setup slave vol for geo-replication
#ssh gfs-node3.prayther.org "lvcreate -L 2G -T rhs_vg/slave"
#ssh gfs-node3.prayther.org "lvcreate -V 2G -T rhs_vg/slave -n slave_vol"
#ssh gfs-node3.prayther.org "mkfs.xfs -f -i size=512 /dev/rhs_vg/slave_vol"
#ssh gfs-node3.prayther.org "mkdir -pv /mnt/slave_vol"
#ssh gfs-node3.prayther.org "echo /dev/rhs_vg/slave_vol /mnt/slave_vol xfs defaults 0 0 >> /etc/fstab"
#ssh gfs-node3.prayther.org "mount -a"
#ssh gfs-node3.prayther.org "gluster volume create slave_vol gfs-node3.prayther.org:/mnt/slave_vol force"
#ssh gfs-node3.prayther.org "gluster volume start slave_vol"
#ssh gfs-node3.prayther.org "gluster volume status slave_vol"
#ssh gfs-node3.prayther.org "gluster volume info slave_vol"

#gluster volume create vol replica 2 gfs-node1.prayther.org:/mnt/lv1/brk1 gfs-node2.prayther.org:/mnt/lv2/brk2

#for i in {1..3};do ssh gfs-node$i.prayther.org "systemctl restart glusterd && sleep 5 && systemctl status glusterd";done
#
#gluster system:: execute gsec_create
#gluster volume set all cluster.enable-shared-storage enable
gluster volume geo-replication gluster_shared_storage gfs-backup.prayther.org::backupvol create push-pem

