#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

#ssh ${GATEWAY}

#Export latest so next time local is used it's more up-to-date
mkdir /mnt/share
echo "10.0.0.1:/var/www/html/uteeg /mnt/share   nfs rw,hard,intr,context="system_u:object_r:httpd_sys_rw_content_t:s0" 0 0" >> /etc/fstab
rmdir /var/lib/pulp/katello-export
/usr/bin/mount -a
cd /var/lib/pulp && /usr/bin/ln -s /mnt/share/katello-export .
exit 1
#hammer content-view version export --id 1
for i in $(hammer --csv repository list --organization redhat | awk -F"," '{print $1}' | grep -v Id | grep -v 5 | grep -v 4| sort -n);do hammer repository export --organization redhat --product-id $i;done
