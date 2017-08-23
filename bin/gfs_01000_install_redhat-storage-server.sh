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

#Install this on gfs nodes: gfs-admin gfs-node1 gfs-node2 gfs-node3

#for i in gfs-admin gfs-node1 gfs-node2 gfs-node3
#  do ssh "${i}" yum -y install ansible gdeploy redhat-storage-server glusterfs-ganesha gstatus sshpass ntpdate nagios-server-addons glusterfs glusterfs-fuse heketi-client heketi ctdb krb5-workstation ntpdate nfs-utils rpcbind cifs-utils samba samba-client samba-winbind samba-winbind-clients samba-winbind-krb5-locator
#done
# yum groupinstall "Infiniband Support"

#systemctl enable glusterd
#systemctl start glusterd
#firewall-cmd --get-active-zones

#firewall-cmd --zone=public --add-service=glusterfs --permanent
#systemctl restart firewalld

#tuned-adm list
#tuned-adm profile rhgs-random-io

# admin node: non interactive, emptly pass ""
if [[ $(hostname -s | awk -F"-" '{print $2}') -eq "admin" ]];then
        ls ~/.ssh/id_rsa && rm -f ~/.ssh/id_rsa
        ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa
fi

# from gfs-admin get everyone talking 
if [[ $(hostname -s | awk -F"-" '{print $2}') -eq "admin" ]];then
        for i in 10.0.0.9 10.0.0.10 10.0.0.11 10.0.0.12 10.0.0.13 10.0.0.14
          do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${i}" || echo "ssh-copy-id -o StrictHostKeyChecking=no ${i} failded" || exit 1
        done
fi

for i in 10.0.0.9 10.0.0.10 10.0.0.11 10.0.0.12 10.0.0.14
  do ssh "${i}" firewall-cmd --zone=public --add-service=glusterfs --permanent && \
          ssh "${i}" firewall-cmd --add-service=rpc-bind --add-service=nfs --permanent && \
          ssh "${i}" systemctl restart firewalld
done

#again with names. having issues with names in some places.
# from gfs-admin get everyone talking
if [[ $(hostname -s | awk -F"-" '{print $2}') -eq "admin" ]];then
        for i in gfs-admin gfs-client gfs-backup gfs-node1 gfs-node2 gfs-node3
          do sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no "${i}" || echo "ssh-copy-id -o StrictHostKeyChecking=no ${i} failded" || exit 1
        done
fi

for i in gfs-admin gfs-backup gfs-node1 gfs-node2 gfs-node3
  do ssh "${i}" firewall-cmd --zone=public --add-service=glusterfs --permanent && \
          ssh "${i}" firewall-cmd --add-service=rpc-bind --add-service=nfs --permanent && \
          ssh "${i}" systemctl restart firewalld
done

#for i in gfs-admin gfs-node1 gfs-node2 gfs-node3
#  do ssh "${i}" yum -y install ansible gdeploy redhat-storage-server glusterfs-ganesha gstatus sshpass ntpdate nagios-server-addons glusterfs glusterfs-fuse heketi-client heketi ctdb krb5-workstation ntpdate nfs-utils rpcbind cifs-utils samba samba-client samba-winbind samba-winbind-clients samba-winbind-krb5-locator
#done


#only run this on admin node gfs-admin, ceph_admin
if [[ $(hostname -s | awk -F"-" '{print $2}') -eq "admin" ]];then
        for i in 10.0.0.10 10.0.0.11 10.0.0.12 10.0.0.14
          do gluster peer probe "${i}"
        done
fi

gluster peer status
echo "###INFO: Finished $0"
echo "###INFO: $(date)"
