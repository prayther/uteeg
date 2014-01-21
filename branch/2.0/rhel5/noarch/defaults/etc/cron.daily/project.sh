#!/bin/bash

# $Id: spawar.sh 763 2012-08-15 13:52:46Z sysutil
# this file maintained by puppet

puppet -d -l /var/log/puppet.log /etc/puppet/manifests/stig.pp > /dev/null
puppet -d -l /var/log/puppet.log /etc/puppet/manifests/site.pp > /dev/null