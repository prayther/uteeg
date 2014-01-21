#!/bin/bash

# $Id: root-grub-passwd.sh 785 2012-08-22 12:19:46Z sysutil $

# set root and grub boot passwds monthly to "mungemonthyear"
# no one but root can see this file, so while the passwd
# is "right there".  the machine would have to be compromised already to see it.
# perms = root.root 700

#set root passwd
monthyear=`date +"%m%Y"`
munge='P@$$w0rdP@$$w0rd'
passwd="$munge$monthyear"

echo "$passwd" | passwd --stdin root

#configure grub passwd with same pass as root
md5=`ircd-mkpasswd -m -p $passwd`
sed -i "/password/ c password --md5 $md5" /boot/grub/grub.conf
