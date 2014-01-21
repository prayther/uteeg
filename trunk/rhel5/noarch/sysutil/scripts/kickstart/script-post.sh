cp /etc/rc.local /etc/rc.local.orig

cat <<'EOF1' > /etc/provision_reboot.sh
#!/bin/bash
cp /etc/rc.local.orig /etc/rc.local
reboot
EOF1

cat <<'EOF2' > /etc/rc.local
> /etc/motd
yum -y update yum
yum -y update
yum -y install puppet-0.25.5 defaults

puppet -l /var/log/puppet_first_run /etc/puppet/manifests/site.pp &
puppet -l /var/log/puppet_first_run /etc/puppet/manifests/stig.pp &
puppet -l /var/log/puppet_first_run /etc/puppet/manifests/site.pp &

/etc/cron.daily/sosreport.sh &

chmod 700 /etc/provision_reboot.sh
/etc/provision_reboot.sh
EOF2

reboot