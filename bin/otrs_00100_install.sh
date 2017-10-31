#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

# bsfl are bash libs used in scripts in uteeg
ls -d ~/bsfl || git clone https://github.com/SkypLabs/bsfl.git /root/bsfl

# read configuration (needs to be adopted!)
#source etc/virt-inst.cfg
source ../etc/virt-inst.cfg
source ../etc/virthost.cfg
source ../etc/rhel.cfg
source ~/bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"0" '{print $2}') -ne "otrs" ]];then
 echo ""
 echo "Need to run this on the 'otrs' node"
 echo ""
 exit 1
fi

echo "mynetworks_style = subnet" >> /etc/postfix/main.cf
if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

#http://doc.otrs.com/doc/manual/admin/stable/en/html/installation.html#installation-of-prepared-packages
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
setenforce permissive

yum -y install mariadb-server
yum -y install --nogpg otrs

sed -i '/\[mysqld]/a innodb_log_file_size\ =\ 256M' /etc/my.cnf.d/server.cnf
sed -i '/\[mysqld]/a query_cache_size\ =\ 32M' /etc/my.cnf.d/server.cnf
sed -i '/\[mysqld]/a max_allowed_packet\ =\ 20M' /etc/my.cnf.d/server.cnf

systemctl restart mariadb
systemctl enable mariadb

echo '

password
password




' | /usr/bin/mysql_secure_installation

systemctl restart httpd.service
#some perl thing in the otrs docs and dovecot for imap
yum -y install "perl(Text::CSV_XS)" dovecot

#these are so rhel users get setup properly. only for testing. "mail_access_groups = mail" allows people to see others mail
echo "mail_location = mbox:~/mail:INBOX=/var/mail/%u" >> /etc/dovecot/conf.d/10-mail.conf
echo "mail_access_groups = mail" >> /etc/dovecot/conf.d/10-mail.conf

systemctl restart dovecot
systemctl enable dovecot

#edit /etc/postfix/main.cf
echo "myorigin = $mydomain" >> /etc/postfix/main.cf
echo "mydestination = $myhostname, localhost.$mydomain, localhost" >> /etc/postfix/main.cf
echo "mynetworks_style = subnet" >> /etc/postfix/main.cf
echo "relay_domains = $mydestination" >> /etc/postfix/main.cf
echo "relayhost = $mydomain" >> /etc/postfix/main.cf

firewall-cmd --zone=public --add-port=5666/tcp --permanent
firewall-cmd --add-service=smtp --add-service=imap --permanent
firewall-cmd --reload
systemctl restart httpd

#goto to configure
#http://sat0otrs.prayther.org/otrs/installer.pl
