#!/bin/bash

# $Id:
# this file maintained by puppet

sleep `echo $$%900 | bc`
puppet -d -l /var/log/puppet.log /etc/puppet/manifests/stig.pp > /dev/null
sleep `echo $$%900 | bc`
puppet -d -l /var/log/puppet.log /etc/puppet/manifests/site.pp > /dev/null

/root/McAfeeVSEForLinux-installer -i

# remove from here down after cleanup
chown root.root /etc
rm -f /update.tar.gz /home/aprayther/register.sh /home/aprayther/defaults* /home/aprayther/issue /home/aprayther/logrotate.conf /home/aprayther/motd /home/praythea/install-linux-LANT.sh