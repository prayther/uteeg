#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source etc/virt-inst.cfg

#exec >> log/virt-inst.log 2>&1
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> log/virt-inst.log; done; }
exec 2> >(LOG_)

cd /root && wget --no-clobber http://${SERVER}/ks/iso/${SATELLITE_ISO}
cd /root && wget --no-clobber http://${SERVER}/ks/iso/${RHEL_ISO}
cd /root && wget --no-clobber http://${SERVER}/ks/manifest/manifest.zip

# Create Repository for Local install
cat << EOF > /etc/yum.repos.d/rhel-dvd.repo
[rhel]
name=RHEL local
baseurl=file:///mnt/rhel
enabled=1
gpgcheck=1
EOF

mkdir /mnt/rhel
mount -o loop /root/${RHEL_ISO} /mnt/rhel
mkdir /mnt/sat
mount -o loop /root/${SATELLITE_ISO} /mnt/sat
cd /mnt/sat
./install_packages
cd /tmp

# After initial install using local media.
# Turn off the local repos and patch from CDN.
#mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
#mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.off

# Unregister so if your are testing over and over you don't run out of subscriptions and annoy folks.
# Register.
#/usr/sbin/subscription-manager unregister
#/usr/sbin/subscription-manager --username="${RHN_USERNAME}" --password="${RHN_PASSWD}" register
#/usr/sbin/subscription-manager attach --pool="${RHN_POOL}"	#8a85f9873f77744e013f8944ab87680b
#/usr/sbin/subscription-manager repos '--disable=*'
#/usr/sbin/subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms
#/usr/bin/yum repolist
#/usr/bin/yum clean all
#/usr/bin/yum -y update
#/usr/bin/yum -y install nfs-utils
#
/usr/bin/firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="69/udp" \
 --add-port="80/tcp"  --add-port="443/tcp" \
 --add-port="5647/tcp" \
 --add-port="8000/tcp" --add-port="8140/tcp"
firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="69/udp" \
 --add-port="80/tcp"  --add-port="443/tcp" \
 --add-port="5647/tcp" \
 --add-port="8000/tcp" --add-port="8140/tcp"

/usr/sbin/satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-initial-location "${LOC}" \
--foreman-admin-username admin \
--foreman-admin-password password \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-servername $(hostname) \
--capsule-puppet false

#Might use this if you install from DVD and then stuff happens ?!$%
#/usr/sbin/satellite-installer --scenario satellite --upgrade

#/usr/sbin/satellite-installer --scenario satellite \
#--foreman-initial-organization "${ORG}" \
#--foreman-initial-location "${LOC}" \
#--foreman-admin-username admin \
#--foreman-admin-password password \
#--foreman-proxy-tftp true \
#--foreman-proxy-tftp-servername $(hostname) \
#--capsule-puppet false

mkdir  ~/.hammer
cat << EOF > ~/.hammer/cli_config.yml
   :foreman:
       :host: https://${VMNAME}.${DOMAIN}
       :username: ${ADMIN}
       :password: ${PASSWD}
       :organization: ${ORG}
EOF

mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.off

/usr/bin/yum clean all
/usr/bin/yum -y update

#/bin/bash /root/uteeg/bin/satellite-update.sh

#Create an organization
#hammer organization create --name=${ORG} --label=${ORG}
#hammer organization add-user --user=admin --name=${ORG}
#Upload our manifest.zip (created in RH Portal) to our org and list our products:

#hammer subscription upload --file /root/manifest.zip  --organization=${ORG}

#hammer product list --organization redhat
#List all repositories included in a previous imported product:
#hammer repository-set list --organization=redhat --product 'Red Hat Enterprise Linux Server'

# timeout for testing.
#hammer settings set --name idle_timeout --value 99999999

## RHEL 7 basic repos from local for speed, then again changing to internet sources to get updated.

#hammer organization update --name redhat --redhat-repository-url http://10.0.0.1/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/
#hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
#hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
## can't use releasesever on this one.
##hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
#hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
#hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
#hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
#hammer product create --organization redhat --name EPEL7
##hammer repository update --url 'http://10.0.0.1/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/' --organization redhat --product EPEL7
##hammer repository create --name='EPEL 7 - x86_64' --organization=redhat --product='EPEL7' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/
#hammer repository create --name='EPEL 7 - x86_64' --organization=redhat --product='EPEL7' --content-type='yum' --publish-via-http=true --url=http://10.0.0.1/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/
#hammer product create --organization redhat --name Check_MK
##chcon -t httpd_sys_content_t apps/check_mk/check-mk-raw-1.4.0p7-el7-54.x86_64.rpm # change selinux context on the repo
#hammer repository create --name='Check_MK' --organization=redhat --product='Check_MK' --content-type='yum' --publish-via-http=true --url=http://10.0.0.1/ks/apps/check_mk


#Study the output
#hammer repository-set list --organization=redhat --product 'Red Hat Enterprise Linux Server'
#Then we can sync all repositories that we've enabled with this simple script:
#hammer --csv repository list --organization=redhat
#for i in $(hammer --csv repository list --organization=redhat  | grep -i "7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=redhat; done
#for i in $(hammer --csv repository list --organization=redhat  | grep -i "Check_MK" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=redhat --async; done
#for i in $(hammer --csv repository list --organization=redhat  | grep -i "7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=redhat --async; done
#for i in $(hammer --csv repository list --organization=redhat  | grep -i "7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=redhat; done
 
# Put CDN back to redhat and sync latest
#hammer organization update --name redhat --redhat-repository-url https://cdn.redhat.com

# Create a new product for Puppet modules in forge (this slows down adding any Puppet module as it re-indexes all of them.  Only add Puppet Forge when you need it.):
# hammer product create --name='Forge' --organization=redhat
# hammer repository create --name='Puppet Forge' --organization=redhat --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com

# Update EPEL repo to point back to public to get latest. After pulling from local above.
#hammer repository update --url 'http://dl.fedoraproject.org/pub/epel/7/x86_64/' --organization redhat --product EPEL7

# Now lets sync from internet
#for i in $(hammer --csv repository list --organization=redhat  | grep -i "7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=redhat; done
#for i in $(hammer --csv repository list --organization=redhat  | grep -i "7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=redhat --async; done

#Export latest so next time local is used it's more up-to-date
#mkdir /mnt/share
#echo "10.0.0.1:/var/www/html/ks	/mnt/share	nfs rw,hard,intr,context="system_u:object_r:httpd_sys_rw_content_t:s0" 0 0" >> /etc/fstab
#/usr/bin/mount -a
#cd /var/lib/pulp && /usr/bin/ln -s /mnt/share/katello-export .
#hammer content-view version export --id 1
##rsync -av /var/lib/pulp/katello-export 10.0.01:/var/www/html/ks/
 
 
#Create a daily sync plan:
#hammer sync-plan create --interval=daily --name='Daily' --organization=redhat --sync-date '2017-07-03 24:00:00' --enabled 1
#hammer sync-plan list --organization=redhat
 
#And associate this plan to our products, it must be done by sync-plan-id, not name otherwise hammer doesn't work:
#hammer product set-sync-plan --sync-plan-id=1 --organization=redhat --name='Red Hat Enterprise Linux Server'
##hammer product set-sync-plan --sync-plan-id=1 --organization=redhat --name='Forge'
#hammer product set-sync-plan --sync-plan-id=1 --organization=redhat --name='EPEL7'

# setup activation keys
# moving to separate script. ak_create.sh
#hammer activation-key create --name='AK_Infra_Dev' --organization=redhat --content-view='CCV_RHEL7_Server' --lifecycle-environment='Infra_Dev'
 
# Leave the repos alone to sync while we go work on other parts of Satellite.
 
#And a new location:
#hammer location create --name=laptop
#hammer location add-user --name=laptop --user=admin
#hammer location add-organization --name=laptop --organization=redhat
 
#Create a domain and associate it to our organization/location:
#hammer domain create --name='anzlab.bne.redhat.com'
#hammer domain list
#hammer organization add-domain --domain-id=1 --name='redhat'
#hammer location add-domain --domain-id=1 --name='laptop'
 
#Create a subnet and associate it to our organization/location:
# The TFTP service/capsule was created as a result of the options passed to the katello-installer command.
#hammer capsule list
#hammer capsule info --id 1
#hammer domain list
#hammer subnet create --domain-ids=1 --gateway='10.64.30.254' --mask='255.255.255.0' --name='10.64.30.0/24'  --tftp-id=1 --network='10.64.30.0' --dns-primary='10.64.30.41'
#hammer organization add-domain --domain-id=1 --name='redhat'
#hammer subnet list
#hammer location add-subnet --subnet-id=1 --name='laptop'
 
#Create 3 lifecycle environment paths
#    Openshift Apps -> Dev -> Prod
#    Public_Website -> Dev -> Test -> Prod
#    App -> Dev -> Test -> UAT -> Prod -> Legacy
 
#hammer lifecycle-environment create --name='Infra_Dev' --prior='Library' --organization="${ORG}"
#hammer lifecycle-environment create --name='Infra_Test' --prior='Infra_Dev' --organization="${ORG}"
#hammer lifecycle-environment create --name='Infra_Prod' --prior='Infra_Test' --organization="${ORG}"
# 
# 
#hammer lifecycle-environment create --name='App_Dev' --prior='Library' --organization="${ORG}"
#hammer lifecycle-environment create --name='App_Test' --prior='App_Dev' --organization="${ORG}"
#hammer lifecycle-environment create --name='App_UAT' --prior='App_Test' --organization="${ORG}"
#hammer lifecycle-environment create --name='App_Prod' --prior='App_UAT' --organization="${ORG}"
 
# This is How I get the ID of a repo by name
#hammer --csv repository list --organization=redhat |  awk -F, '/^[0-9]*?,Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server/ {print $1}'
 
 
#Create a content view for RHEL 7 Core server x86_64:
#hammer content-view create --name='CV_RHEL7_Core' --organization=redhat
#for i in $(hammer --csv repository list --organization=redhat | grep "Linux 7 " | grep -v Optional | grep -v Extras | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Core' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
#hammer content-view publish --name="CV_RHEL7_Core" --organization=redhat #--async
 
#Create a content view for RHEL 7 Extras server x86_64:
#hammer content-view create --name='CV_RHEL7_Extras' --organization=redhat
#for i in $(hammer --csv repository list --organization=redhat | grep "Linux 7 " | grep Extras | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Extras' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
#hammer content-view publish --name="CV_RHEL7_Extras" --organization=redhat #--async
 
#Create a content view for RHEL 7 Optional server x86_64:
#hammer content-view create --name='CV_RHEL7_Optional' --organization=redhat
#for i in $(hammer --csv repository list --organization=redhat | grep "Linux 7 " | grep Optional | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Optional' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
#hammer content-view publish --name="CV_RHEL7_Optional" --organization=redhat #--async
 
#Create a content view for EPEL 7 x86_64e:
#hammer content-view create --name='CV_EPEL7' --organization=redhat
#for i in $(hammer --csv repository list --organization=redhat | grep "EPEL7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_EPEL7' --organization=redhat --repository-id=${i}; done
#for i in $(hammer --csv repository list --organization=redhat | grep "EPEL7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_EPEL7' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
#hammer content-view publish --name="CV_EPEL7" --organization=redhat #--async
 
#Create a content view for Check_MK:
#hammer content-view create --name='CV_Check_MK' --organization=redhat
#for i in $(hammer --csv repository list --organization=redhat | grep "Check_MK" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_Check_MK' --organization=redhat --repository-id=${i}; done
#
#Publish the content views to Library:
#hammer content-view publish --name="CV_Check_MK" --organization=redhat #--async
 
 
#COMP_RHEL7=$(hammer content-view version list  --organization=redhat  --content-view CV_RHEL7_Core | awk '/CV_RHEL7_Core/ {print $1}')
#COMP_Check_MK=$(hammer content-view version list  --organization=redhat  --content-view CV_Check_MK | awk '/CV_Check_MK/ {print $1}')
# CCVs would contain the RHEL 7 Core Server.
#hammer content-view create --organization=redhat --name="CCV_RHEL7_Server" --composite  --component-ids="${COMP_RHEL7}" --description="Combines RHEL 7 with Basic Core Server"
#hammer content-view publish --name="CCV_RHEL7_Server" --organization=redhat --async
 
# CCVs would contain the Check_MK application and RHEL 7 Core Server.
#hammer content-view create --organization=redhat --name="CCV_Check_MK" --composite  --component-ids="${COMP_RHEL7},${COMP_Check_MK}" --description="Combines RHEL 7 with the Check_MK application"
#hammer content-view publish --name="CCV_Check_MK" --organization=redhat --async
 
 

###################################################################################################
###################################################################################################
# Still not super clear on collection hosts
###################################################################################################
###################################################################################################
 
#Create a host collection for RHEL7:
#hammer host-collection create --name='HC_RHEL_7' --organization=redhat
#hammer host-collection create --name='HC_Check_MK' --organization=redhat
 
# Operating Systems are automatically added as the kickstart repos are synchronised.
# Associate the operating systems hosted on this server with the specified organisation and location.
#ORG='redhat'
#LOC='laptop'
#for i in $(hammer --csv medium list | grep $(hostname) | cut -d, -f1)
#do
#   hammer organization add-medium --name ${ORG} --medium-id ${i}
#   hammer location add-medium --name ${LOC} --medium-id ${i}
#done

#set really idle use timeout
#hammer settings set --name idle_timeout --value 99999999

#/usr/bin/yum -y install ansible --enablerepo=epel
#restore rc.local after we install
#cp /root/rc.local.orig /etc/rc.d/rc.local
#chmod u-x /etc/rc.d/rc.local
#systemctl disable rc-local
exit 0
