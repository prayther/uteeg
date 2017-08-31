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

#check to make sure all machines are ready
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org gfs-backup.prayther.org
          do ssh "${i}" exit || echo "ssh to ${i} failded" || exit 1
done
#########################################################################################

#Remember that snap-max-soft-limit is expressed as a percentage of snap-max-hard-limit. In this case, 48 snapshots is 75% of 64.
echo y | gluster snapshot config snap-max-hard-limit 64 \
 snap-max-soft-limit 75

#Enable automatic deletion of snapshots when snap-max-soft-limit is exceeded.
gluster snapshot config auto-delete enable

#Enable automatic activation of new snapshots.
gluster snapshot config activate-on-create enable

#ssh rhel-client.prayther.org "umount -v /mnt/distreplvol/"
ssh rhel-client.prayther.org "mkdir -pv /mnt/distreplvol/"

#Enable user-serviceable snapshots
gluster volume set distreplvol features.uss enable

ssh rhel-client.prayther.org "mount -t glusterfs gfs-node2:/distreplvol /mnt/distreplvol"

#Enable shared storage for Red Hat Gluster Storage.
#already done in previous script
gluster volume set all cluster.enable-shared-storage enable

#allow crond access to files labeled fusefs_t
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" "setsebool -P cron_system_cronjob_use_shares 1"
done

#initialize the snapshot scheduler.
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" "mount -t glusterfs gfs-node2:/distreplvol /mnt/distreplvol"
done

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" "snap_scheduler.py init"
done

#on one srv enable the snapshot scheduler.
ssh gfs-admin.prayther.org "snap_scheduler.py enable"

#Create a new schedule, called hourly, that takes a new snapshot of the snapvol volume every hour.
ssh gfs-admin.prayther.org "snap_scheduler.py add minutes '*/2 * * * *' distreplvol"

ssh gfs-admin.prayther.org "snap_scheduler.py list"
ssh gfs-admin.prayther.org "gluster snapshot list"



echo "###INFO: Finished $0"
echo "###INFO: $(date)"
