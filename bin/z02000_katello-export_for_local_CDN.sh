#!/bin/bash -x

# This script is set to "off" so as not to run automatically when configuring Satellite.
# This script exports all repositories base on hammer --csv repository list --organization="${ORG}"
# This is dependent on having your Kick Start server httpd setup with an NFS connection to export to /var/www/html/ks/katello-exports

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
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

# Install nfs-utils if not already
ssh ${GATEWAY} "rpm -q nfs-utils || dnf install -y nfs-utils"
# open firewall to all for nfs if not already
ssh ${GATEWAY} "firewall-cmd --list-all | grep -i services | grep nfs || firewall-cmd --permanent --add-service=nfs"
# Add entry in exports so export of katello content-views are possible in one step for maintaining local CDN
ssh ${GATEWAY} grep "/var/www/html/uteeg" /etc/exports || echo "/var/www/html/uteeg     *(rw,no_acl)" >> /etc/exports
ssh ${GATEWAY} chmod 0777 -R /var/www/html/uteeg/katello-export

#Export latest so next time local is used it's more up-to-date
mkdir /mnt/share
grep "${GATEWAY}:/var/www/html/uteeg /mnt/share   nfs rw,hard,intr,context=" /etc/fstab || echo "${GATEWAY}:/var/www/html/uteeg /mnt/share   nfs rw,hard,intr,context="system_u:object_r:httpd_sys_rw_content_t:s0" 0 0" >> /etc/fstab
rmdir /var/lib/pulp/katello-export
/usr/bin/mount -a
mount | grep "${GATEWAY}:/var/www/html/uteeg" && ln -s /mnt/share/katello-export/ /var/lib/pulp/
# If there is not EXPORTIME var in ../etc/virt-inst.cfg then this has not run before and this will be the first date
grep ^EXPORTIME= ../etc/virt-inst.cfg || echo EXPORTIME=\"$(date "+%FT%T.%X %Z")\" >> ../etc/virt-inst.cfg
# put the new EXPORTIME each run and then you have since
hammer content-view version export --since="${EXPORTIME}" --id 1
echo EXPORTIME=\"$(date "+%FT%T.%X %Z")\" >> ../etc/virt-inst.cfg

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
