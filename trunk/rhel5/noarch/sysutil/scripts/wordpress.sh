#!/bin/bash -x

# $Id: wordpress.sh 785 2012-08-22 12:19:46Z sysutil $

# Redirect all stdout and stderr to mytest.log
#exec > wordpress.sh.log 2>&1
exec >> /var/log/wordpress.sh.log 2>&1

# sleep for 5 because i am running the data collection on all the servers at the same time.  otherwise, some or most will show yesterdays date/data
sleep 2900

# this loop looks in ~sysutil/sim/* and awks out $SERVICENAME$ENVIRONMETNCAPS ie: SIMDEV, creates a new /var/www/html/sim/addBlogPost$CATEGORY.php,
# from the /var/www/html/sim/addBlogPost-template.php, template.  sets $category= and $keywords= once (this is important that it happens once
# so that all boxes from a particular, $SERVICENAME$ENVIRONMETNCAPS, can be put on one blog post each time.  
# next it takes all the vars from the files in ~sysutil/sim/*, created on each box and sent over here.
# now the sed command will have a -i, to edit "in place" and append the details of each server in a particular $SERVICENAME$ENVIRONMETNCAPS CATEGORY

# if $NETWEBID is not set then "?" is the default that just gives you a netweb asset: search page
NETWEBID="?"

# get 1 blog input php file for each CATEGORY, eliminating duplicates
for i in \
  `ls ~sysutil/sim/`
    do CATEGORY=`awk -F"|" '{ print $6$3 }' ~sysutil/sim/$i` \
      && echo $CATEGORY
done | sort | uniq > /var/www/html/sim/sort.uniq.CATEGORY

for CATEGORY in \
  `cat /var/www/html/sim/sort.uniq.CATEGORY`
    do cp /var/www/html/sim/addBlogPost-template.php /var/www/html/sim/addBlogPost$CATEGORY.php
done

# make a copy of the "master" template to work with on this run.
# this is for the CM page only
/bin/cp /var/www/html/sim/addBlogPost_CM-template.php /var/www/html/sim/addBlogPost_CM.php

# this section sets up the html tables for the entire service/env and gives it the label for the given  service/env
# below in the for loop that hits all servers, reporting in, we'll setup just <tr> 

sed -i "/##START##/a <!-- ##END_TABLE## -->" /var/www/html/sim/addBlogPost_CM.php

sed -i "/##END_TABLE##/a </html>" /var/www/html/sim/addBlogPost_CM.php
sed -i "/##END_TABLE##/a </table>" /var/www/html/sim/addBlogPost_CM.php
sed -i "/##END_TABLE##/a </tr>" /var/www/html/sim/addBlogPost_CM.php
sed -i "/##END_TABLE##/a </td>" /var/www/html/sim/addBlogPost_CM.php

  for CATEGORY in \
    `tac /var/www/html/sim/sort.uniq.CATEGORY | grep -v SIM`
       do     sed -i "/##START##/a <!-- $CATEGORY##END_SERVICE_TABLE## -->" /var/www/html/sim/addBlogPost_CM.php
              sed -i "/##START##/a <!-- $CATEGORY##END_ROLES_TABLE## -->" /var/www/html/sim/addBlogPost_CM.php
              sed -i "/##START##/a <!-- $CATEGORY##START_ROLES_TABLE## -->" /var/www/html/sim/addBlogPost_CM.php
            sed -i "/##START##/a <!-- $CATEGORY##START_SERVICE_TABLE## -->" /var/www/html/sim/addBlogPost_CM.php

                sed -i "/$CATEGORY##START_SERVICE_TABLE##/a <!-- $CATEGORY##SERVICE## -->" /var/www/html/sim/addBlogPost_CM.php
                  sed -i "/$CATEGORY##START_ROLES_TABLE##/a <!-- $CATEGORY##ROLES## -->" /var/www/html/sim/addBlogPost_CM.php

            sed -i "/$CATEGORY##START_SERVICE_TABLE##/a <td>" /var/www/html/sim/addBlogPost_CM.php
            sed -i "/$CATEGORY##START_SERVICE_TABLE##/a <tr>" /var/www/html/sim/addBlogPost_CM.php
            sed -i "/$CATEGORY##START_SERVICE_TABLE##/a <table border=0>" /var/www/html/sim/addBlogPost_CM.php
              sed -i "/$CATEGORY##START_ROLES_TABLE##/a <table border=0>" /var/www/html/sim/addBlogPost_CM.php
              sed -i "/$CATEGORY##START_ROLES_TABLE##/a </table>" /var/www/html/sim/addBlogPost_CM.php
            sed -i "/$CATEGORY##END_SERVICE_TABLE##/a </table>" /var/www/html/sim/addBlogPost_CM.php
            sed -i "/$CATEGORY##END_SERVICE_TABLE##/a </tr>" /var/www/html/sim/addBlogPost_CM.php
            sed -i "/$CATEGORY##END_SERVICE_TABLE##/a </td>" /var/www/html/sim/addBlogPost_CM.php


                     sed -i "/$CATEGORY##SERVICE##/a </table>" /var/www/html/sim/addBlogPost_CM.php
                     sed -i "/$CATEGORY##SERVICE##/a <td><font size=4 style=text-align:center;>##$CATEGORY##ENV_LONG</font></td>" /var/www/html/sim/addBlogPost_CM.php
                     sed -i "/$CATEGORY##SERVICE##/a <td><b><font size=4 style=text-align:center;color:darkgreen;>NIPR</font></b></td>" /var/www/html/sim/addBlogPost_CM.php
                     sed -i "/$CATEGORY##SERVICE##/a <td><b><font size=4 style=text-align:center;color:darkgreen;>(##$CATEGORY##SERVICENAME)</font></b></td>" /var/www/html/sim/addBlogPost_CM.php
                     #sed -i "/$CATEGORY##SERVICE##/a <td><font size=4 style=background-color:honeydew;text-align:center;>##$CATEGORY##SERVICE_LONG</font></td>" /var/www/html/sim/addBlogPost_CM.php && \
                     sed -i "/$CATEGORY##SERVICE##/a <td><b><font size=4 style=text-align:center;>##$CATEGORY##SERVICE_LONG</font></b></td>" /var/www/html/sim/addBlogPost_CM.php
                     sed -i "/$CATEGORY##SERVICE##/a <table border=0>" /var/www/html/sim/addBlogPost_CM.php

  done

# this sets up first, all emcompassing table for the whole page.
# another options would be to have this in the "template.php" file
# thought it would be better to control everything in one place
sed -i "/##START##/a <!-- ##START_TABLE## -->" /var/www/html/sim/addBlogPost_CM.php

sed -i "/##START_TABLE##/a <td>" /var/www/html/sim/addBlogPost_CM.php
sed -i "/##START_TABLE##/a <tr>" /var/www/html/sim/addBlogPost_CM.php
sed -i "/##START_TABLE##/a <table border=0>" /var/www/html/sim/addBlogPost_CM.php
sed -i "/##START_TABLE##/a <html>" /var/www/html/sim/addBlogPost_CM.php


####
####
# this starts the second loop that grabs the csv filem, that is reported in with /etc/cron.daily/sosreport.sh script ~sysutil/sim/


for i in \
  `ls -r ~sysutil/sim/`
    do TIMESTAMP=`awk -F"|" '{ print $1 }' ~sysutil/sim/$i`
       ROLE=`awk -F"|" '{ print $2 }' ~sysutil/sim/$i`
       CATEGORY=`awk -F"|" '{ print $6$3 }' ~sysutil/sim/$i`
       ENVIRONMENTCAPS=`awk -F"|" '{ print $3 }' ~sysutil/sim/$i`
       ENVIRONMENT=`awk -F"|" '{ print $4 }' ~sysutil/sim/$i`
       POC=`awk -F"|" '{ print $5 }' ~sysutil/sim/$i`
       SERVICENAME=`awk -F"|" '{ print $6 }' ~sysutil/sim/$i`
       MAC=`awk -F"|" '{ print $7 }' ~sysutil/sim/$i`
       IP=`awk -F"|" '{ print $8 }' ~sysutil/sim/$i`
       HOSTNAME=`awk -F"|" '{ print $9 }' ~sysutil/sim/$i`
       FQDN=`awk -F"|" '{ print $10 }' ~sysutil/sim/$i`
       REDHATRELEASE=`awk -F"|" '{ print $11 }' ~sysutil/sim/$i`
       ARCH=`awk -F"|" '{ print $12 }' ~sysutil/sim/$i`
       KERNELVERSION=`awk -F"|" '{ print $13 }' ~sysutil/sim/$i`
       SERVICENAMELOWER=`awk -F"|" '{ print $15 }' ~sysutil/sim/$i`
       DSEVERSION=`awk -F"|" '{ print $16 }' ~sysutil/sim/$i`
       APACHECTL=`awk -F"|" '{ print $17 }' ~sysutil/sim/$i`
       EMVERSION=`awk -F"|" '{ print $18 }' ~sysutil/sim/$i`
       JETTY=`awk -F"|" '{ print $19 }' ~sysutil/sim/$i`
       RABBITMQ=`awk -F"|" '{ print $20 }' ~sysutil/sim/$i`
       DERBY=`awk -F"|" '{ print $21 }' ~sysutil/sim/$i`
       ESMMANAGER=`awk -F"|" '{ print $22 }' ~sysutil/sim/$i`
       ESMMONITOR=`awk -F"|" '{ print $23 }' ~sysutil/sim/$i`
       ESMCONSOLE=`awk -F"|" '{ print $24 }' ~sysutil/sim/$i`
       ESMDASHBOARD=`awk -F"|" '{ print $25 }' ~sysutil/sim/$i`
       ESMHOME=`awk -F"|" '{ print $26 }' ~sysutil/sim/$i`
       LDAP=`awk -F"|" '{ print $27 }' ~sysutil/sim/$i`
       ORACLE=`awk -F"|" '{ print $28 }' ~sysutil/sim/$i`
       POSTGRESPOSTGRES=`awk -F"|" '{ print $29 }' ~sysutil/sim/$i`
       POSTGRESENTERPRISEDB=`awk -F"|" '{ print $30 }' ~sysutil/sim/$i`
       JAVA=`awk -F"|" '{ print $31 }' ~sysutil/sim/$i`
       TOMCAT=`awk -F"|" '{ print $32 }' ~sysutil/sim/$i`
       CDDA=`awk -F"|" '{ print $33 }' ~sysutil/sim/$i`
       EC=`awk -F"|" '{ print $34 }' ~sysutil/sim/$i`
       ESH=`awk -F"|" '{ print $35 }' ~sysutil/sim/$i`
       FSA=`awk -F"|" '{ print $36 }' ~sysutil/sim/$i`
       ANT=`awk -F"|" '{ print $37 }' ~sysutil/sim/$i`
       NUTCH=`awk -F"|" '{ print $38 }' ~sysutil/sim/$i`
       MARKLOGIC=`awk -F"|" '{ print $39 }' ~sysutil/sim/$i`
       SONIC=`awk -F"|" '{ print $40 }' ~sysutil/sim/$i`
       JUM=`awk -F"|" '{ print $41 }' ~sysutil/sim/$i`
       SEROS=`awk -F"|" '{ print $42 }' ~sysutil/sim/$i`
       MYSQL=`awk -F"|" '{ print $43 }' ~sysutil/sim/$i`
       M2M=`awk -F"|" '{ print $44 }' ~sysutil/sim/$i`
       MULE=`awk -F"|" '{ print $45 }' ~sysutil/sim/$i`

         if [ $ENVIRONMENT == "ti" ];then
           ENVIRONMENT_LONG="Test \& Integration Environment"
         fi
         if [ $ENVIRONMENT == "ri" ];then
           ENVIRONMENT_LONG="Reference Implementation Environment"
         fi
         if [ $ENVIRONMENT == "sb" ];then
           ENVIRONMENT_LONG="Sandbox Environment"
         fi
         if [ $SERVICENAME == "CDDA" ];then
           SERVICENAME_LONG="Content Discoverable Deployment Architecture"
         fi
         if [ $SERVICENAME == "DSE" ];then
           SERVICENAME_LONG="Data Services Environment"
         fi
         if [ $SERVICENAME == "EM" ];then
           SERVICENAME_LONG="Enterprise Messaging"
         fi
         if [ $SERVICENAME == "ESB" ];then
           SERVICENAME_LONG="Enterprise Service Bus"
         fi
         if [ $SERVICENAME == "ESM" ];then
           SERVICENAME_LONG="Enterprise Services Monitoring"
         fi
         if [ $SERVICENAME == "JUM" ];then
           SERVICENAME_LONG="Joint User Messaging"
         fi
         if [ $SERVICENAME == "LDAP" ];then
           SERVICENAME_LONG="Directory Services"
         fi
         if [ $SERVICENAME == "SIM" ];then
           SERVICENAME_LONG="Standardized Infrastructure Management"
         fi
         if [ $SERVICENAME == "ORACLE" ];then
           SERVICENAME_LONG="Oracle Database"
         fi
         if [ $SERVICENAME == "POSTGRES" ];then
         SERVICENAME_LONG="Postgres Database"
         fi
         if [ $SERVICENAME == "TOMCAT" ];then
           SERVICENAME_LONG="Tomcat Web Services"
         fi
         if [ $SERVICENAME == "STRATEGICWATCH" ];then
           SERVICENAME_LONG="STRATEGICWATCH Services"
         fi
         if [ $SERVICENAME == "MARKLOGIC" ];then
           SERVICENAME_LONG="Marklogic Services"
         fi
         if [ $SERVICENAME == "M2M" ];then
           SERVICENAME_LONG="Machine to Machine Messaging"
         fi
         if [ $SERVICENAME == "JUM" ];then
           SERVICENAME_LONG="Joint User Messaging"
         fi

         sed -i "s/SERVICENAME/$SERVICENAME/g" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "s/ENVIRONMENTCAPS/$ENVIRONMENTCAPS/g" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a </td>" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <a href="http://rhn.chs.spawar.navy.mil/sos/$HOSTNAME/archive/\?C=M\;O=D" target="_blank">SOS Report Archive</a><br />" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <a href="http://rhn.chs.spawar.navy.mil/sos/$HOSTNAME/$HOSTNAME/sos_reports/sosreport.html" target="_blank">Current SOS Report</a> $TIMESTAMP <b>Netweb: </b><a href="https://netweb.spawar.navy.mil/assets/asset_view.php?asset_id=$NETWEBID" target="_blank">$HOSTNAME</a>" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <b>POC: </b>$POC" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <b>Operating System Version: </b>RHEL$REDHATRELEASE <b>Kernel: </b>$KERNELVERSION $ARCH<br />" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <b>FQDN: </b>$FQDN <b>IP: </b>$IP <b>MAC: </b>$MAC<br />" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <b>Service Information: </b><a href="http://rhn.chs.spawar.navy.mil/sos/$HOSTNAME/$HOSTNAME/sos_reports/sosreport.html#`echo $SERVICENAME | tr [A-Z] [a-z]`" target="_blank">$SERVICENAME</a><br />" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a <b><font size="3">$SERVICENAMELOWER-$ROLE-$HOSTNAME</font></b><br />" /var/www/html/sim/addBlogPost$CATEGORY.php
         sed -i "/##START##/a _______________________________" /var/www/html/sim/addBlogPost$CATEGORY.php


#"role" in a service
          if [ "$SERVICENAME" != "SIM" ];then
          if [ "$SERVICENAME" != "" ];then
            sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a </tr>" /var/www/html/sim/addBlogPost_CM.php
            sed -i "s/##$SERVICENAME$ENVIRONMENTCAPS##ENV_LONG/$ENVIRONMENT_LONG/g" /var/www/html/sim/addBlogPost_CM.php
            sed -i "s/##$SERVICENAME$ENVIRONMENTCAPS##SERVICENAME/$SERVICENAME/g" /var/www/html/sim/addBlogPost_CM.php
            sed -i "s/##$SERVICENAME$ENVIRONMENTCAPS##SERVICE_LONG/$SERVICENAME_LONG/g" /var/www/html/sim/addBlogPost_CM.php
              if [ "$JAVA" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$JAVA</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Java:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$MULE" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$MULE</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Mule:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$M2M" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$M2M</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>M2M:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$MYSQL" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$MYSQL</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>MySQL:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$SEROS" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$SEROS</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Seros:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$JUM" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$JUM</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>JUM:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$SONIC" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$SONIC</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Sonic:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$MARKLOGIC" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$MARKLOGIC</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Marklogic:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$NUTCH" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$NUTCH</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>NUTCH:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ANT" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ANT</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ANT:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$FSA" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$FSA</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>FSA:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ESH" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ESH</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ESH:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$EC" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$EC</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>EC:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$CDDA" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$CDDA</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>CDDA:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$TOMCAT" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$TOMCAT</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Tomcat:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$POSTGRESPOSTGRES" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$POSTGRESPOSTGRES</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Postgres:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$POSTGRESENTERPRISEDB" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$POSTGRESENTERPRISEDB</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Postgres:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ORACLE" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ORACLE</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Oracle:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$LDAP" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$LDAP</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>LDAP:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ESMMANAGER" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ESMMANAGER</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ESM Manager:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ESMMONITOR" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ESMMONITOR</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ESM Monitor:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ESMCONSOLE" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ESMCONSOLE</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ESM Console:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ESMDASHBOARD" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ESMDASHBOARD</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ESM Dashboard:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ESMHOME" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$ESMHOME</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>ESM Home:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$DERBY" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$DERBY</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Apache Derby:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$RABBITMQ" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$RABBITMQ</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>RabbitMQ:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$JETTY" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$JETTY</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Jetty:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$EMVERSION" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$EMVERSION</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>EM:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$APACHECTL" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$APACHECTL</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Apache:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$DSEVERSION" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$DSEVERSION</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>DSE:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$KERNELVERSION" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$KERNELVERSION</font></td>" /var/www/html/sim/addBlogPost_CM.php
                  sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>Kernel:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$REDHATRELEASE" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:lavender;>$REDHATRELEASE</font></td>" /var/www/html/sim/addBlogPost_CM.php
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:bisque;>RHEL:</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$ROLE" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:honeydew;>$ROLE</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              #uncomment 3 lines below to show hostnames, for development purposes.
              if [ "$IP" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:honeydew;>$IP</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
              if [ "$HOSTNAME" != "" ];then
                sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <td><font size=2 style=background-color:honeydew;>$HOSTNAME</font></td>" /var/www/html/sim/addBlogPost_CM.php
              fi
            sed -i "/$SERVICENAME$ENVIRONMENTCAPS##ROLES##/a <tr>" /var/www/html/sim/addBlogPost_CM.php
          fi
          fi
#"role" in a service

####
# need to build the "Data Service Environment (DSE)     NIPR    Sandbox Environment" section for each service
# putting a key section in each one so that we can go back and append from last to first line, for each box in this group
#
# this is what we're trying to build
#      <table border="0">
#        <td><font size=4 style="text-align:center;">Data Service Environment (DSE)</font></b></td>
#        <td><b><font size=4 style="text-align:center;color:darkgreen;">NIPR</font></b></td>
#        <td><font size=4 style="text-align:center;">Sandbox Environment</font></td>
#      </table>

done

# this is for services
for i in \
  `ls ~sysutil/sim/`
    do CATEGORY=`awk -F"|" '{ print $6$3 }' ~sysutil/sim/$i`
      echo $CATEGORY
done | sort | uniq > /var/www/html/sim/sort.uniq.CATEGORY

# this is for services
for i in \
  `cat /var/www/html/sim/sort.uniq.CATEGORY`
    do php /var/www/html/sim/addBlogPost$i.php
done

# cleans up all the files that were delivered for workpress.sh to work on
for i in `ls ~sysutil/sim/`
  do SERVICENAME=`awk -F"|" '{ print $6 }' ~sysutil/sim/$i`
     ROLE=`awk -F"|" '{ print $2 }' ~sysutil/sim/$i`
     HOSTNAME1=`awk -F"|" '{ print $9 }' ~sysutil/sim/$i`
     /bin/rm -f ~sysutil/sim/$SERVICENAME-$ROLE-$HOSTNAME1
done

# had a problem with <!-- comment statements causing formatting issues
# instead of fixing it...
cat  /var/www/html/sim/addBlogPost_CM.php | grep -v ^\<\!-- > /var/www/html/sim/addBlogPost_CM.workaround.php
# this is for CM
 php /var/www/html/sim/addBlogPost_CM.workaround.php

# needs to stay "blue" color coded as a comment, or likely i missed a closing quote above.  just a visual queue