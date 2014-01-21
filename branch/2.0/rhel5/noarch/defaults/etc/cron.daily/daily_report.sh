#!/bin/bash -x

# Redirect all stdout and stderr to log
exec > /var/log/sosreport.sh.log 2>&1
# $Id: sosreport.sh 773 2012-08-17 16:04:46Z sysutil $
# This file is auto generated with puppet.  Anything modfified will be lost at the next run.
DIRNAME=`date +'%s'`
TIMESTAMP=`date +'%x,%R'`
HOSTNAME=`hostname -s`
ROLE=`grep ^$HOSTNAME /etc/puppet/hosts.master.txt | awk -F, '{ print $26 }'`
ENVIRONMENTCAPS=`grep ^$HOSTNAME /etc/puppet/hosts.master.txt | awk -F, '{ print $33 }' | tr "[:lower:]" "[:upper:]"`
ENVIRONMENT=`grep ^$HOSTNAME /etc/puppet/hosts.master.txt | awk -F, '{ print $33 }'`
POC=`grep ^$HOSTNAME /etc/puppet/hosts.master.txt | awk -F, '{ print $10 }'`
SERVICENAME=`grep ^$HOSTNAME /etc/puppet/hosts.master.txt | awk -F, '{ print $47 }'`
SERVICENAMELOWER=`grep ^$HOSTNAME /etc/puppet/hosts.master.txt | awk -F, '{ print $47 }' | tr "[:upper:]" "[:lower:]"`
MAC=`ifconfig eth0 | grep HWaddr | awk '{ print $5 }'`
IP=`ifconfig eth0 | grep Bcast | awk -F: '{ print $2 }' | awk '{ print $1 }'`
FQDN=`hostname`
REDHATRELEASE=`cat /etc/redhat-release | awk '{ print $7 '}`
ARCH=`uname -p`
KERNELVERSION=`uname -r`
DATE=`date +"%m-%d-%y"`
SIMHOST="sim"
#DATE="04-01-13"
#KERNELRELEASEDATE=`uname -v`

# DSE section
#if [ `grep $HOSTNAME  | awk -F, '{ print $47 }' | tr [A-Z] [a-z]` == "dse" ];then
  # check to see if this "version" file exist and then set a var with contents, to be used on http://sim wordpress.sh
  # using awk as well at the end because it had some leading spaces that would make the report look sloppy
  # of course this will likely break when the next time the file is generated slightly different ;)

  if [ -d /opt/tomcat/webapps/esm-home/META-INF/ ];then
    ESMHOME=`grep -iR "Implementation-Version" /opt/tomcat/webapps/esm-home/META-INF/MANIFEST.MF | awk -F" " '{ print $2 }' | awk -F"-" '{ print $1 }'`
  fi
  if [ -d /opt/tomcat/webapps/esm-dashboard/META-INF/ ];then
    ESMDASHBOARD=`grep -iR "Implementation-Version" /opt/tomcat/webapps/esm-dashboard/META-INF/MANIFEST.MF | awk -F" " '{ print $2 }' | awk -F"-" '{ print $1 }'`
  fi
  if [ -d /opt/tomcat/webapps/esm-console/META-INF/ ];then
    ESMCONSOLE=`grep -iR "Implementation-Version" /opt/tomcat/webapps/esm-console/META-INF/MANIFEST.MF | awk -F" " '{ print $2 }' | awk -F"-" '{ print $1 }'`
  fi
  if [ -d /opt/tomcat/webapps/esm-monitor/META-INF/ ];then
    ESMMONITOR=`grep -iR "Implementation-Version" /opt/tomcat/webapps/esm-monitor/META-INF/MANIFEST.MF | awk -F" " '{ print $2 }' | awk -F"-" '{ print $1 }'`
  fi
  if [ -d /opt/tomcat/webapps/esm-manager/META-INF/ ];then
    ESMMANAGER=`grep -iR "Implementation-Version" /opt/tomcat/webapps/esm-manager/META-INF/MANIFEST.MF | awk -F" " '{ print $2 }' | awk -F"-" '{ print $1 }'`
  fi
  if [ -f /opt/tomcat-dse/webapps/dse/WEB-INF/app/views/layouts/_version.html.haml ];then
    DSEVERSION=`grep Version /opt/tomcat-dse/webapps/dse/WEB-INF/app/views/layouts/_version.html.haml | awk '{ print $2 }'`
  fi
  if [ -f /usr/sbin/apachectl ];then
    APACHECTL=`/usr/sbin/apachectl -version | awk -F"/" '{ print $2 }'`
  fi
  if [ -f  /opt/messaging/etc/VERSION.txt ];then
    EMVERSION=`grep '^POM Version' /opt/messaging/etc/VERSION.txt | awk '{ print $NF }'`
  fi
  if [ -f  /opt/messaging/lib/jetty-servlet-*.jar ];then
    JETTY=`ls /opt/messaging/lib/jetty-servlet-*.jar | sed -e 's#/opt/messaging/lib/jetty-servlet-##' -e 's#\.jar##'`
  fi
  if [ -d  /opt/rabbitmq/rabbitmq_server-* ];then
    RABBITMQ=`ls -d /opt/rabbitmq/rabbitmq_server-* | sed 's#/opt/rabbitmq/rabbitmq_server-##'`
  fi
  if [ -f  /opt/messaging/lib/derby-*.jar ];then
    DERBY=`ls /opt/messaging/lib/derby-*.jar | sed -e 's#/opt/messaging/lib/derby-##' -e 's#\.jar##'`
  fi
  if [ -f /usr/sbin/slapd ];then
    LDAP=`rpm -q openldap | uniq | awk -F"-" '{ print $2 }'`
  fi
  if [ -d /opt/oracle ];then
    ORACLE=`echo "sqlplus" | su - oracle | grep Release | awk -F" " '{ print $3 }'`
  fi
  if [ -d /opt/PostgresPlus ];then
    POSTGRESENTERPRISEDB=`su -l enterprisedb -c "cd /opt/PostgresPlus/9.0AS/bin/ && ./psql --version" | grep psql | awk -F" " '{ print $3 }'`
  fi
  if [ -d /opt/PostgreSQL ];then
    POSTGRESPOSTGRES=`su -l postgres -c "psql --version" | grep psql | awk -F" " '{ print $3 }'`
  fi
  if [ `locate version.sh | grep tomcat` ];then
    TOMCAT=$(thefile=`locate version.sh | grep tomcat` && $thefile | grep 'JVM Version' | awk '{ print $3 }')
  fi
  if [ -d /cdda/install ];then
    CDDA=`head -1 /cdda/install/README.txt | awk '{print $NF}' | tr -d v`
  fi
  if [ -d /cdda/webapps/ec ];then
    EC=`strings /cdda/webapps/ec/releasenotes.jsp | egrep -om1 'Version [.0-9]+' | awk '{print $NF}'`
  fi
  if [ -d /cdda/webapps/es ];then
    ESH=`strings /cdda/webapps/es/releasenotes.jsp | egrep -om1 'Version [.0-9]+' | awk '{print $NF}'`
  fi
  if [ -d /cdda/webapps/fsa ];then
    FSA=`strings /cdda/webapps/fsa/releasenotes.jsp | egrep -om1 'Version [.0-9]+' | awk '{print $NF}'`
  fi
  if [ -d /cdda/apache-ant ];then
    ANT=`/cdda/apache-ant/bin/ant -version | egrep -o 'version ([.0-9]+)' | awk '{print $NF}'`
  fi
  if [ -d /cdda/apache-ant ];then
    NUTCH=`ls /cdda/nutch/nutch-*.jar | sed 's/^.*-//;s/\.jar$//'`
  fi
  if [ `rpm -qa | grep -i marklogic` ];then
    MARKLOGIC=`rpm -qa | grep -i marklogic | awk -F"-" '{ print $2"-"$3 }'`
  fi
  if [ -d /opt/Sonic/MQ7.6 ];then
    SONIC=`cat /opt/Sonic/MQ7.6/update.properties | grep full.version | awk -F"=" '{ print $2 }'`
  fi
  if [ -f /MSP/msg/data/jum.version.properties ];then
    JUM=`cat /MSP/msg/data/jum.version.properties | awk -F"=" '{ print $2 }'`
  fi
  if [ -f /MSP/msg/bin/messaging.sh ];then
    SEROS=`/MSP/msg/bin/messaging.sh license | grep "Seros Information Distribution Server" | awk '{ print $6 }'`
  fi
  if [ -d /COTS ];then
    MYSQL=`find /COTS -type f -name mysql -exec '{}' -V ';' | awk '{ print $5 }' | grep -v denied | awk -F, '{ print $1 }' | sort -r | head -1`
  fi
  if [ -f /opt/Messaging/VERSION ];then
    M2M=`cat /opt/Messaging/VERSION`
  fi
  if [ -d /opt/esb/mule-* ];then
    MULE=`ls -d /opt/esb/mule-* | awk -F"-" '{ print $4 }'`
  fi
  # run this on all...
    JAVA=`find /opt /usr /bin /sbin -type f -name java -exec "{}" -version ";" 2>&1 | grep "java version" | tr -d \" | awk '{print $NF}' | sort -r | head -1`
#fi


su -l sysutil -c "ssh -o StrictHostKeyChecking=no $SIMHOST mkdir -p /home/sysutil/sim/"
su -l sysutil -c "mkdir -p /home/sysutil/sim/"
su -l sysutil -c "echo '$TIMESTAMP|$ROLE|$ENVIRONMENTCAPS|$ENVIRONMENT|$POC|$SERVICENAME|$MAC|$IP|$HOSTNAME|$FQDN|$REDHATRELEASE|$ARCH|$KERNELVERSION|$KERNELRELEASEDATE|$SERVICENAMELOWER|$DSEVERSION|$APACHECTL|$EMVERSION|$JETTY|$RABBITMQ|$DERBY|$ESMMANAGER|$ESMMONITOR|$ESMCONSOLE|$ESMDASHBOARD|$ESMHOME|$LDAP|$ORACLE|$POSTGRESPOSTGRES|$POSTGRESENTERPRISEDB|$JAVA|$TOMCAT|$CDDA|$EC|$ESH|$FSA|$ANT|$NUTCH|$MARKLOGIC|$SONIC|$JUM|$SEROS|$MYSQL|$M2M|$MULE' > /home/sysutil/sim/$SERVICENAME-$ROLE-$HOSTNAME"
su -l sysutil -c "/usr/bin/scp /home/sysutil/sim/$SERVICENAME-$ROLE-$HOSTNAME $SIMHOST:/home/sysutil/sim/"

mkdir -p /tmp/$DIRNAME
if [ $? == 0 ];then
  echo "/n
  " | sosreport 2>&1>/dev/null
fi

mv /tmp/sosreport*bz2 /tmp/$DIRNAME/
if [ $? == 0 ];then
  cd /tmp/$DIRNAME/ && tar jxf *
  mv `ls -d * | grep -v bz2` `hostname | awk -F. '{ print $1 }'`
  mv `ls -d sosreport*` sosreport-$HOSTNAME-$DATE.tar.bz2
  chmod -R 755 /tmp/$DIRNAME/
fi

# send it over to host "rhn" to be viewed/downloaded, http://rhn/sos
su -l sysutil -c "ssh -o StrictHostKeyChecking=no rhn mkdir -p /var/www/html/sos/$HOSTNAME/archive/monthly"
su -l sysutil -c "ssh rhn rm -rf /var/www/html/sos/$HOSTNAME/$HOSTNAME"
#su -l sysutil -c "ssh rhn find /var/www/html/sos/$HOSTNAME/$HOSTNAME/archive -name '*.bz2' -mtime +31 -exec rm -f {} ;"
#su -l sysutil -c "ssh rhn find /var/www/html/sos/$HOSTNAME/$HOSTNAME/archive/monthly -name '*.bz2' -mtime +365 -exec rm -f {} ;"
su -l sysutil -c "ssh rhn find /var/www/html/sos/$HOSTNAME/archive -name "*.bz2" -mtime +31 | xargs rm -f"
su -l sysutil -c "ssh rhn find /var/www/html/sos/$HOSTNAME/archive/monthly -name "*.bz" | xargs rm -f"
su -l sysutil -c "rsync -a /tmp/$DIRNAME/$HOSTNAME sysutil@rhn:/var/www/html/sos/$HOSTNAME/"
if [ `echo $DATE | awk -F"-" '{ print $2 }'` == "01" ];then
  su -l sysutil -c "rsync -a /tmp/$DIRNAME/*.bz2 sysutil@rhn:/var/www/html/sos/$HOSTNAME/archive/monthly"
  else
  su -l sysutil -c "rsync -a /tmp/$DIRNAME/*.bz2 sysutil@rhn:/var/www/html/sos/$HOSTNAME/archive/"
fi

rm -rf /tmp/$DIRNAME /tmp/sosreport* /tmp/sos_*