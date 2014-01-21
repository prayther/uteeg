#!/bin/bash

# $Id: root-grub-passwd.sh 1123 2012-11-26 17:26:28Z sysutil $

# set root and grub boot passwds monthly to "mungemonthyear"
# no one but root can see this file, so while the passwd
# is "right there".  the machine would have to be compromised already to see it.
# perms = root.root 700

#set root passwd
monthyear=`date +"%m%Y"`
syshostname=`hostname -s`
munge='iuyIUYiuy*&^876*&^'
passwd="$munge$monthyear$syshostname"

echo "$passwd" | passwd --stdin root

#configure grub passwd with same pass as root
md5=`ircd-mkpasswd -m -p $passwd`
sed -i "/password/ c password --md5 $md5" /boot/grub/grub.conf

# restart hbss
/sbin/service cma restart