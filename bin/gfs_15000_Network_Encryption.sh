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

#this script can be run multiple times with a few precautions like umounting
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org
  do ssh "${i}" "umount /var/run/gluster/shared_storage/"
done

#stop all gluster volumes
gluster volume geo-replication labvol \
	geouser@gfs-backup.prayther.org::backupvol stop

for vols in $(gluster volume list);do echo y | gluster volume stop ${vols};done

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" "sleep 60 && systemctl restart glusterd"
done

#gluster volume start gluster_shared_storage

#Generate a private key for each system.
#Use the generated private key to create a signed certificate by running the following command:
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org
  do ssh "${i}" "openssl genrsa -out /etc/ssl/glusterfs.key 2048"
     ssh "${i}" "openssl req -new -x509 -key /etc/ssl/glusterfs.key -subj "/CN=${i}" -days 365 -out /etc/ssl/glusterfs.pem"
done

#look at files
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org
  do ssh "${i}" "openssl rsa -in /etc/ssl/glusterfs.key -check"
     ssh "${i}" "openssl rsa -noout -text -in /etc/ssl/glusterfs.key"
     ssh "${i}" "openssl rsa -noout -modulus -in /etc/ssl/glusterfs.key | openssl md5"
     ssh "${i}" "openssl x509 -noout -in /etc/ssl/glusterfs.pem -text"
done

#For self signed CA certificates on servers, collect the .pem certificates of clients and servers, that is, /etc/ssl/glusterfs.pem files from every system. Concatenate the collected files into a single file.
#Place this file in /etc/ssl/glusterfs.ca on all the servers in the trusted storage pool.
cat /dev/null > /etc/ssl/glusterfs.ca
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org
  do scp "${i}":/etc/ssl/glusterfs.pem /var/tmp/glusterfs_"${i}".pem
	  cat /var/tmp/glusterfs_"${i}".pem >> /etc/ssl/glusterfs.ca
done
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org
  do scp /etc/ssl/glusterfs.ca "${i}":/etc/ssl/
done

#verify the ca chain
openssl verify -verbose -purpose sslserver -CAfile /etc/ssl/glusterfs.pem /etc/ssl/glusterfs.ca

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" "sleep 60 && systemctl restart glusterd"
done

gluster volume start gluster_shared_storage

ssh rhel-client.prayther.org "mkdir -pv /var/run/gluster/shared_storage/"
ssh rhel-client.prayther.org "mount -t glusterfs gfs-node2:/gluster_shared_storage /var/run/gluster/shared_storage/"

#Set the list of common names of all the servers to access the volume. Be sure to include the common names of clients which will be allowed to access the volume.
for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org rhel-client.prayther.org
  do ssh "${i}" "mkdir -pv /var/lib/glusterd/" && \
	  ssh "${i}" "touch /var/lib/glusterd/secure-access"
done

gluster volume set gluster_shared_storage auth.ssl-allow \
	'gfs-admin.prayther.org,gfs-node1.prayther.org,gfs-node2.prayther.org,gfs-node3.prayther.org,rhel-client.prayther.org'

echo y | gluster volume stop gluster_shared_storage

#Enable the client.ssl and server.ssl options on the volume.
gluster volume set gluster_shared_storage client.ssl on
gluster volume set gluster_shared_storage server.ssl on

gluster volume start gluster_shared_storage
gluster volume info gluster_shared_storage
gluster volume status gluster_shared_storage

ssh rhel-client.prayther.org "umount /var/run/gluster/shared_storage/"
ssh rhel-client.prayther.org "mount -t glusterfs gfs-node1:/gluster_shared_storage /var/run/gluster/shared_storage/"
ssh rhel-client.prayther.org grep "SSL /var/log/glusterfs/run-gluster-shared_storage.log" #should see 'SSL support on the I/O path is ENABLED', 'SSL support for glusterd is ENABLED', 'SSL verification succeeded'

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org
  do ssh "${i}" "sleep 60 && systemctl restart glusterd"
done

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
