#Export latest so next time local is used it's more up-to-date
mkdir /mnt/share
echo "10.0.0.1:/var/www/html/ks /mnt/share      nfs rw,hard,intr,context="system_u:object_r:httpd_sys_rw_content_t:s0" 0 0" >> /etc/fstab
/usr/bin/mount -a
cd /var/lib/pulp && /usr/bin/ln -s /mnt/share/katello-export .
hammer content-view version export --id 1

