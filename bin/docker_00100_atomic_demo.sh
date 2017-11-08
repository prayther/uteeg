#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
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
export HOME=/root


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

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "virt" ]];then
 echo ""
 echo "Need to run this on the 'virt' node"
 echo ""
 exit 1
fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

#build a atomic host manuall, then run this on it
#https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/single/getting_started_with_containers/#creating_and_running_the_mariadb_database_server_container
#demo docker db container
docker pull rhel7:latest
mkdir ~/mydbcontainer
curl -O https://access.redhat.com/webassets/avalon/d/Red_Hat_Enterprise_Linux_Atomic_Host-7-Getting_Started_with_Containers-en-US/files/mariadb_cont_2.tgz
cp mariadb_cont*.tgz ~/mydbcontainer
cd ~/mydbcontainer
tar xvf mariadb_cont*.tgz

docker build -t dbforweb .
docker run -dit -p 3306:3306 --restart always --name=mydbforweb dbforweb

#demo docker http and db backend
#https://access.redhat.com/articles/1328953
mkdir ~/mywebcontainer
curl -O https://access.redhat.com/sites/default/files/attachments/web_cont_2.tgz
cp web_cont*.tgz ~/mywebcontainer
cd ~/mywebcontainer
tar xvf web_cont*.tgz

DOCKERIP=$(ip a | grep docker0 | grep inet | awk '{print $2}' | awk -F"/" '{print $1}')

echo << "EOF" > ~/mywebcontainer/action
#!/usr/bin/python
# -*- coding: utf-8 -*-
import MySQLdb as mdb
import os

con = mdb.connect(os.getenv('DB_SERVICE_SERVICE_HOST',"${DOCKERIP}"), 'dbuser1', 'redhat', 'gss')

with con:

    cur = con.cursor()
    cur.execute("SELECT MESSAGE FROM atomic_training")

    rows = cur.fetchall()

    print 'Content-type:text/html\r\n\r\n'
    print '<html>'
    print '<head>'
    print '<title>My Application</title>'
    print '</head>'
    print '<body>'

    for row in rows:
        print '<h2>' + row[0] + '</h2>'

    print '</body>'
    print '</html>'

    con.close()
EOF

docker build -t webwithdb .
docker run -dit -p 80:80 --restart always --name=mywebwithdb webwithdb

#test
curl http://localhost/index.html
#The Web Server is Running
curl http://localhost/cgi-bin/action
#RedHat rocks Success

#docker rm 4dda510c529e8b46830e1ae0dcbc497a93ef8ed0d800a2218cbe39dc67c45472
#docker run -dit -p 3306:3306 --restart always --name=mydbforweb dbforweb
#docker run -dit -p 80:80 --restart always --name=mywebwithdb webwithdb

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
