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
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "gfs" ]];then
 echo ""
 echo "Need to run this on the 'gfs' node"
 echo ""
 exit 1
fi

if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
 echo ""
 echo "Need to run this on the 'admin' node"
 echo ""
 exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org gfs-backup.prayther.org
  do ssh "${i}" firewall-cmd --zone=public --add-port=5666/tcp --permanent && \
          ssh "${i}" systemctl restart firewalld
done

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org gfs-backup.prayther.org
  do ssh "${i}" "sed -i '/^allowed_hosts/ s/$/,gfs-admin.prayther.org/' /etc/nagios/nrpe.cfg"
done

for i in gfs-admin.prayther.org gfs-node1.prayther.org gfs-node2.prayther.org gfs-node3.prayther.org gfs-backup.prayther.org
  do ssh "${i}" "systemctl restart nrpe"
done

yum -y install nagios-server-addons mutt sendmail
sed -i /Addr=127.0.0.1/d /etc/mail/sendmail.mc
systemctl enable sendmail
systemctl start sendmail

#this might help with the questions
#almost works but not quite. have to hit enter for a few questions
#echo \n \n \n | configure-gluster-nagios -c gluster-cluster -H gfs-admin.prayther.org
configure-gluster-nagios -c gluster-cluster -H gfs-admin.prayther.org
nagios -v /etc/nagios/nagios.cfg

#Modify contact_name, alias, and email directives in /etc/nagios/gluster/gluster-contacts.cfg to reflect student
#Add the contact name student for gluster-service and gluster-generic-host in /etc/nagios/gluster/gluster-templates.cfg.
#if geouser is not found add section
if [[ ! $(grep geouser@localhost /etc/nagios/gluster/gluster-contacts.cfg) ]];then
cat << "EOF" >> /etc/nagios/gluster/gluster-contacts.cfg
define contact {
       contact_name                  student
       alias                         student
       email                         geouser@localhost
       service_notification_period   24x7
       service_notification_options  w,u,c,r,f,s
       service_notification_commands notify-service-by-email
       host_notification_period      24x7
       host_notification_options     d,u,r,f,s
       host_notification_commands    notify-host-by-email
}
EOF
fi

# search for contacts, add ',student' to end of line
if [[ ! $(grep snmp,student /etc/nagios/gluster/gluster-templates.cfg) ]];then
sed -i '/contacts/ s/$/,student/' /etc/nagios/gluster/gluster-templates.cfg
fi

#Add $NOTIFICATIONCOMMENT$\n directly before | /bin/mail -s in /etc/nagios/objects/commands.cfg for both notify-service-by-email and notify-host-by-email definitions.
#search for '" |' and replace with  '$NOTIFICATIONCOMMENT$\n\" |'
sed -i 's/"\ |/\ $NOTIFICATIONCOMMENT$\\n\" |/g' /etc/nagios/objects/commands.cfg

#Enable profiling
gluster volume  profile labvol start
gluster volume info labvol #diagnostics.count-fop-hits: on
gluster volume profile labvol info cumulative
gluster volume  profile labvol stop #turn it off
gluster volume top labvol open #View the performance metrics of bricks

mutt

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
