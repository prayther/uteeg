#!/bin/bash -x

MYHOSTNAME=`hostname -s`
HOSTCSV=`sudo grep ^$MYHOSTNAME /etc/puppet/manifests/nodes/hosts.master.txt`
ENVIRONMENT1=`echo $HOSTCSV | awk -F, '{ print $33 }'`
VERSION1=`echo $HOSTCSV | awk -F, '{ print $38 }' | rev | cut -b-1`

if [ "$ENVIRONMENT1" == "ri" ] && [ "$VERSION1" == "5" ]
      then ACTIVATIONKEY="42-ecb3847a4d86900c8393ce5322b91b8e"
fi

if [ "$ENVIRONMENT1" == "ri" ] && [ "$VERSION1" == "6" ]
      then ACTIVATIONKEY="42-cafe1df954cef4f0501edc1cc94daedb"
fi

if [ "$ENVIRONMENT1" == "sb" ] && [ "$VERSION1" == "5" ]
      then ACTIVATIONKEY="42-548d88f9b096667eb6b2dda5c272add1"
fi

if [ "$ENVIRONMENT1" == "sb" ] && [ "$VERSION1" == "6" ]
      then ACTIVATIONKEY="42-716bbfbab61d938d2a4e524d5bd54a8a"
fi

if [ "$ENVIRONMENT1" == "ti" ] && [ "$VERSION1" == "5" ]
      then ACTIVATIONKEY="42-02d75b24dd30a49b74a85a300f9226cc"
fi

if [ "$ENVIRONMENT1" == "ti" ] && [ "$VERSION1" == "6" ]
      then ACTIVATIONKEY="42-b7a85e310f439d6769fc23fd174180d7"
fi

sudo /usr/sbin/rhnreg_ks --force --username admin-ges --password P@$$w0rdP@$$w0rd082012 --activationkey $ACTIVATIONKEY --serverUrl https://rhn/XMLRPC


echo "[main]" | sudo tee /etc/yum.conf
echo "cachedir=/var/cache/yum/\$basearch/\$releasever" | sudo tee -a /etc/yum.conf
echo "keepcache=0" | sudo tee -a /etc/yum.conf
echo "debuglevel=2" | sudo tee -a /etc/yum.conf
echo "logfile=/var/log/yum.log" | sudo tee -a /etc/yum.conf
echo "exactarch=1" | sudo tee -a /etc/yum.conf
echo "obsoletes=1" | sudo tee -a /etc/yum.conf
echo "gpgcheck=1" | sudo tee -a /etc/yum.conf
echo "plugins=1" | sudo tee -a /etc/yum.conf
echo "installonly_limit=3" | sudo tee -a /etc/yum.conf
echo "" | sudo tee -a /etc/yum.conf
echo "#  This is the default, if you make this bigger yum won't see if the metadata" | sudo tee -a /etc/yum.conf
echo "# is newer on the remote and so you'll "gain" the bandwidth of not having to" | sudo tee -a /etc/yum.conf
echo "# download the new metadata and "pay" for it by yum not having correct" | sudo tee -a /etc/yum.conf
echo "# information." | sudo tee -a /etc/yum.conf
echo "#  It is esp. important, to have correct metadata, for distributions like" | sudo tee -a /etc/yum.conf
echo "# Fedora which don't keep old packages around. If you don't like this checking" | sudo tee -a /etc/yum.conf
echo "# interupting your command line usage, it's much better to have something" | sudo tee -a /etc/yum.conf
echo "# manually check the metadata once an hour (yum-updatesd will do this)." | sudo tee -a /etc/yum.conf
echo "# metadata_expire=90m" | sudo tee -a /etc/yum.conf
echo "" | sudo tee -a /etc/yum.conf
echo "# PUT YOUR REPOS HERE OR IN separate files named file.repo" | sudo tee -a /etc/yum.conf
echo "# in /etc/yum.repos.d" | sudo tee -a /etc/yum.conf
