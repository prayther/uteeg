#!/bin/bash -x

# $Id: isogen.sh 315 2011-10-05 18:57:02Z sysutil $

exec >> /var/log/sim-provision.log 2>&1

#  this script creates iso boot images to kickstart a rhel server from.
#  while a little cumbersome, compared to pxe, etc it does eliminate
# the need to host pxe and dhcp

PROGNAME=$(basename $0)
function error_exit
{

#       ----------------------------------------------------------------
#       Function for exit due to fatal program error
#               Accepts 1 argument:
#                       string containing descriptive error message
#       ----------------------------------------------------------------


        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        echo "${PROGNAME}: ${1:-"Unknown Error"}" | /bin/mail -s "${PROGNAME}: ${1:-"Unknown Error"}" root@localhost
        exit 1
}

# Example call of the error_exit function.  Note the inclusion
# of the LINENO environment variable.  It contains the current
# line number.

source $HOME/scripts/config.cfg || error_exit "Line $LINENO $HOST: Could not source config.cfg"

# structure of the hosts, comman delimited file

# 1)data,2)00:50:56:00:00:d8,3)150.125.72.68,4)NCES,5)aprayther,6)c2ebl012.c2e.lab,7)20000,8)384,9)nces1,10)Aaron_Prayther_aprayther@LCE.com_843-218-2178/858-334-3171,11)rhel5_64Guest,12)Trusted VM Network,13)ges,14)1,15)thin,16)2048,17)1024,18)2048,19)1024,20)1024,21)512,22)1024,23)512,24)2048,25)1024,26)role,27)255.255.255.0,28)150.125.72.1,29)150.125.132.20,30)150.125.132.24,31)GES,32)0,33)ti,34)[ISOfiles],35)aprayther,36)qweQWE123!@#123,37)c2e-vcenter,38)rhel5,39)x86_64,40)chs.spawar.navy.mil,41)eth0,42)admin-nces,43)P@$$w0rd,44)root,45)'N3ccJt0cc!N3ccJt0cc!',46)2,47)ESM

# 1#hostname,2#macaddress,3#ipaddress,4#resourcepool,5#folder,6#vmhostserver,7#drivesize,8#memoryrequired,9#datastorename,10#notesforvm,11#guestostype,12#networkname,13#projectname,14#numbercpu,15#diskstorageformat,16#swap,17#root,18#var,19#varlog,20#varlogaudit,21#home,22#opt,23#data,24#usr,25#tmp,26#role,27#mask,28#gateway,29#dns1,30#dns2,31#datacenter,32#nic_power_on,33#environment"ti""dev""ri""tst""prod""etc",34#ISOdatastore,35#vcenter user,36#vcenter password,37#vcenter,38#rhelversion,39#architecture,40#domainname,41#nic,42#satuser,43#satpassword,44#bladehostuser,45#bladehostPassword,46#satorganizationid,47#ServiceName

# the sed command, strips spaces out of the "hosts" comma delimited fields. if you ever have to use
# those fields after what perl is parsing above, it would break the data.  this is being done
# because cutused like this inside of the `for loop` sees spaces as fields even though
# "-d," is specified.  don't know a solution yet.
#if [ -f /home/vi-admin/scripts/provision.request.from.sim ]; then
for vm in `cat $HOSTS | sed -e 's/\ /_/g'`; do
  SWAP=`echo $vm | cut -d, -f16`
  ROOT=`echo $vm | cut -d, -f17`
  VAR=`echo $vm | cut -d, -f18`
  VARLOG=`echo $vm | cut -d, -f19`
  VARLOGAUDIT=`echo $vm | cut -d, -f20`
  HOMEDIR=`echo $vm | cut -d, -f21`
  OPT=`echo $vm | cut -d, -f22`
  DATA=`echo $vm | cut -d, -f23`
  USR=`echo $vm | cut -d, -f24`
  TMP=`echo $vm | cut -d, -f25`
  HOST=`echo $vm | cut -d, -f1`
  DOMAIN=`echo $vm | cut -d, -f40`
  MAC=`echo $vm | cut -d, -f2`
  IF=`echo $vm | cut -d, -f41`
  IP=`echo $vm | cut -d, -f3`
  GATEWAY=`echo $vm | cut -d, -f28`
  MASK=`echo $vm | cut -d, -f27`
  DNS1=`echo $vm | cut -d, -f29`
  DNS2=`echo $vm | cut -d, -f30`
  FOLDER=`echo $vm | cut -d, -f5`
  NOTE=`echo $vm | cut -d, -f10`
  PROJECT=`echo $vm | cut -d, -f13`
  ROLE=`echo $vm | cut -d, -f26`
  DATACENTER=`echo $vm | cut -d, -f31`
  ENV=`echo $vm | cut -d, -f33`
  VMHOSTSERVER=`echo $vm | cut -d, -f6`
  ISODATASTORE=`echo $vm | cut -d, -f34`
  DATACENTER=`echo $vm | cut -d, -f31`
  VCENTERUSER=`echo $vm | cut -d, -f35`
  VCENTERPASSWORD=`echo $vm | cut -d, -f36`
  VCENTERSERVER=`echo $vm | cut -d, -f37`
  SATUSER=`echo $vm | cut -d, -f42`
  SATPASSWORD=`echo $vm | cut -d, -f43`
  BLADEHOSTUSER=`echo $vm | cut -d, -f44`
  BLADEHOSTPASSWORD=`echo $vm | cut -d, -f45`
  SATORGANIZATIONID=`echo $vm | cut -d, -f46`

rm -f /home/vi-admin/scripts/provision.request.from.sim

    # write the partition file for kickstart
    cd $SCRIPTS/vmware/ && cp partitioning.template $IP.partitioning
    sed -i "s/<swap>/$SWAP/g" $IP.partitioning
    sed -i "s/<root>/$ROOT/g" $IP.partitioning
    sed -i "s/<var>/$VAR/g" $IP.partitioning
    sed -i "s/<varlog>/$VARLOG/g" $IP.partitioning
    sed -i "s/<varlogaudit>/$VARLOGAUDIT/g" $IP.partitioning
    sed -i "s/<home>/$HOMEDIR/g" $IP.partitioning
    sed -i "s/<opt>/$OPT/g" $IP.partitioning
    sed -i "s/<data>/$DATA/g" $IP.partitioning
    sed -i "s/<usr>/$USR/g" $IP.partitioning
    sed -i "s/<tmp>/$TMP/g" $IP.partitioning
    scp -i ../sysutil.private $IP.partitioning sysutil@$SATSERVER:/var/www/html/partition.files/
    ssh -i ../sysutil.private sysutil@$SATSERVER chmod 755 /var/www/html/partition.files/$IP.partitioning
    rm -f $IP.partitioning

    # clean up old kickstart file, if exist and create a new one via clone from the "template".
    cd $SCRIPTS/vmware/ && ssh -i ../sysutil.private sysutil@$SATSERVER spacecmd -y --username=$SATUSER --password=$SATPASSWORD -- kickstart_delete "$ROLE-$ENV-$HOST"
    ssh -i ../sysutil.private sysutil@$SATSERVER spacecmd -y --username=$SATUSER --password=$SATPASSWORD -- kickstart_clone --name template-rhel-5-x86_64-server --clonename $ROLE-$ENV-$HOST \
    || error_exit "Line $LINENO $HOSTNAME:  ssh -i ../sysutil.private sysutil@$SATSERVER spacecmd -y --username=$SATUSER --password=$SATPASSWORD -- kickstart_clone --name template --clonename $ROLE-$ENV-$HOST"
    ssh -i ../sysutil.private sysutil@$SATSERVER spacecmd -y --username=$SATUSER --password=$SATPASSWORD -- kickstart_addoption $ROLE-$ENV-$HOST network "'network --device $IF --bootproto static --hostname $HOST.$DOMAIN --ip $IP --gateway $GATEWAY --netmask $MASK --nameserver $DNS1,$DNS2'"

    # Ryan Fenno perl script that  grabs "hosts" file and creates the vmcreate.xml
    echo $vm | sed 's/Trusted_VM_Network/Trusted\ VM\ Network/g' > makeXMLConfigFile.in
    cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/makeXMLConfigFile.pl \
    || error_exit "Line $LINENO $HOST: Error cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/makeXMLConfigFile.pl"
    # vmcreate based on the vmcreate.xml file that makeXMLConfigFile.pl creates above from the "hosts" file
    cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/vmcreate.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --filename vmcreate.xml --schema vmcreate.xsd \
    || error_exit "Line $LINENO $HOST: Error cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/vmcreate.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --filename vmcreate.xml --schema vmcreate.xsd"
    # was using the drs-control-final.pl to disable drs, so that a vm would not "move around" while i'm trying to work on it, vifi and vmreconfig require the esxi host rather than vcenter name
    # it seemed to work great, put the individual vm into "drs disabled" but it still moved around
    # so now using whichClusterisMyVMin.pl to identify the esxi host
    #$SCRIPTS/vmware/drs-control-final.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST --ipaddress $IP --mode disable
    $SCRIPTS/vmware/changeVMMac.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST --mac $MAC

    # make the bootable iso for kickstart
    # create the host.iso... if the name is kept simple it will be more likely that we won't
    # create what turns out to be duplicates with slightly different names, using up disk
    # space on the datastore
    [ -d $ISODIR ] || mkdir $ISODIR \
    || error_exit "Line $LINENO $HOST: [ -d $ISODIR ] || mkdir $ISODIR "
# need to add an if statement looking for '6' in $ENV var delineating rhel6 versus rhel5 (the default) and use the rhel6 boot isolinux
  echo $ENV | grep 6
    if [ $? == "0" ];then
      cd ../isoBoot6 && sed "s/<PROFILE>/$HOST/g" isolinux/isolinux.cfg.template > isolinux/isolinux.cfg \
      || error_exit "Line $LINENO $HOSTNAME: cd ../isoBoot6 && sed "s/<PROFILE>/$HOST/g" isolinux/isolinux.cfg.template > isolinux/isolinux.cfg"
      else
        cd ../isoBoot && sed "s/<PROFILE>/$HOST/g" isolinux/isolinux.cfg.template > isolinux/isolinux.cfg \
        || error_exit "Line $LINENO $HOSTNAME: cd ../isoBoot && sed "s/<PROFILE>/$HOST/g" isolinux/isolinux.cfg.template > isolinux/isolinux.cfg"
    fi
    sed -i "s/<IP>/$IP/g" isolinux/isolinux.cfg
    sed -i "s/<SATSERVER>/$SATSERVER/g" isolinux/isolinux.cfg
    sed -i "s/<ROLE-ENV-HOST>/$ROLE-$ENV-$HOST/g" isolinux/isolinux.cfg
    sed -i "s/<SATORGANIZATIONID>/$SATORGANIZATIONID/g" isolinux/isolinux.cfg
    sed -i "s/<PROJECT>/$PROJECT/g" isolinux/isolinux.cfg
    sed -i "s/<IF>/$IF/g" isolinux/isolinux.cfg
    sed -i "s/<IP>/$IP/g" isolinux/isolinux.cfg
    sed -i "s/<GATEWAY>/$GATEWAY/g" isolinux/isolinux.cfg
    sed -i "s/<MASK>/$MASK/g" isolinux/isolinux.cfg
    sed -i "s/<DNS1>/$DNS1/g" isolinux/isolinux.cfg
    mkisofs -o ./$HOST.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -l -r -T -v -V "$HOST" . \
    || error_exit "Line $LINENO $HOSTNAME: mkisofs -o ./$HOST.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -l -r -T -v -V "$HOST" ."
    /bin/mv $HOST.iso $ISODIR/ || error_exit "Line $LINENO $HOSTNAME:  /bin/mv $HOST.iso $ISODIR/"

    # get the iso up to the datastore
    vifs --server $VMHOSTSERVER --username $BLADEHOSTUSER --password $BLADEHOSTPASSWORD -p "$ISODIR/$HOST.iso" "[$ISODATASTORE] $PROJECT/$HOST.iso" -Z "$DATACENTER" \
    || error_exit "Line $LINENO $HOSTNAME: vifs --server $VMHOSTSERVER --username $BLADEHOSTUSER --password $BLADEHOSTPASSWORD -p "$ISODIR/$HOST.iso" "$ISODATASTORE $PROJECT/$HOST.iso" -Z "$DATACENTER""

    # reconfigure vm, adding a CDROM
    ESXIHOSTRIGHTNOW=`cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/whichClusterIsMyVMin.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST  | grep hosted | cut -d'"' -f4`
    cd $SCRIPTS/vmware/ && cp vmreconfig.xml.template vmreconfig.xml
    sed -i "s/<VMNAME>/$PROJECT-$ROLE-$ENV-$HOST/g" vmreconfig.xml && sed -i "s/<ESXIHOST>/$ESXIHOSTRIGHTNOW/g" vmreconfig.xml
    cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/vmreconfig.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --schema vmreconfig.xsd --filename vmreconfig.xml
    # now that we have a cdrom, lets put the kickstart iso in it...
    cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/vmISOManagement.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST --operation mount --datastore $ISODATASTORE --filename $PROJECT/$HOST.iso
    $SCRIPTS/vmware/powerops.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST --operation poweron

    # annotate the vm
    echo "$PROJECT-$ROLE-$ENV-$HOST###"$PROJECT-$ROLE-$ENV-$HOST $IP $MAC==$NOTE==Version 1 built @ `date`"" > addVMAnnotation.input \
    || error_exit "Line $LINENO $HOSTNAME: echo "$PROJECT-$ROLE-$ENV-$HOST###"$PROJECT-$ROLE-$ENV-$HOST $IP $MAC==$NOTE"" > addVMAnnotation.input"
    cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/addVMAnnotation.pl --annotationfile addVMAnnotation.input --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER \
    || error_exit "Line $LINENO $HOSTNAME:cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/addVMAnnotation.pl --annotationfile addVMAnnotation.input --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER"

#    sleep 80
#    $SCRIPTS/vmware/vmISOManagement.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST --operation umount
    #cd $SCRIPTS/vmware/ && $SCRIPTS/vmware/drs-control-final.pl --username $VCENTERUSER --password $VCENTERPASSWORD --server $VCENTERSERVER --vmname $PROJECT-$ROLE-$ENV-$HOST --ipaddress $IP --mode restore

#rm -f /home/vi-admin/scripts/provision.request.from.sim
done


