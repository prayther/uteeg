#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg
#source ../etc/enable_rhel.cfg
source ../etc/install-configure-satellite.cfg

exec >> ../log/enable_rhel.log 2>&1

## RHEL 7 basic repos from local for speed, then again changing to internet sources to get updated.
#/usr/bin/hammer organization update --name ${ORG} --redhat-repository-url ${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/
#hammer organization update --name ${ORG} --redhat-repository-url https://cdn.redhat.com
#/usr/bin/hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
#/usr/bin/hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
#/usr/bin/hammer repository-set enable --organization "$ORG" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'
#hammer organization update --name ${ORG} --redhat-repository-url ${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/

###########################
#cleanup and add to epel, check_mk
###########################
# Then we can sync all repositories that we've enable
#for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put CDN back to redhat and sync latest
#/usr/bin/hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
#for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

#Create a content view for RHEL 7 Core server x86_64:
hammer content-view create --name='CV_RHEL7_Core' --organization="${ORG}"
for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep -v Optional | grep -v Extras | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Core' --organization="${ORG}" --repository-id=${i}; done

#Publish the content views to Library:
hammer content-view publish --name="CV_RHEL7_Core" --organization="${ORG}" #--async

#Create a content view for RHEL 7 Extras server x86_64:
#hammer content-view create --name='CV_RHEL7_Extras' --organization="${ORG}"
#for i in $(hammer --csv repository list --organization="${ORG}" | grep "Linux 7 " | grep Extras | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Extras' --organization="${ORG}" --repository-id=${i}; done

#Publish the content views to Library:
#hammer content-view publish --name="CV_RHEL7_Extras" --organization="${ORG}" #--async

#Create a content view for RHEL 7 Optional server x86_64:
#hammer content-view create --name='CV_RHEL7_Optional' --organization="${ORG}"
#for i in $(hammer --csv repository list --organization="${ORG}" | grep "Linux 7 " | grep Optional | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Optional' --organization="${ORG}" --repository-id=${i}; done

#Publish the content views to Library:
#hammer content-view publish --name="CV_RHEL7_Optional" --organization="${ORG}" #--async


###########################
#cleanup and add to epel, check_mk


###########################
#Create a daily sync plan:
#/usr/bin/hammer sync-plan create --interval=daily --name='Daily' --organization="${ORG}" --sync-date '2017-07-03 24:00:00' --enabled 1
#/usr/bin/hammer sync-plan list --organization="${ORG}"

#And associate this plan to our products, it must be done by sync-plan-id, not name otherwise hammer doesn't work:
#/usr/bin/hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Enterprise Linux Server'
#hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Forge'
#hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='EPEL7'

#COMP_RHEL7=$(hammer content-view version list  --organization="${ORG}"  --content-view CV_RHEL7_Core | awk '/CV_RHEL7_Core/ {print $1}')
#COMP_Check_MK=$(hammer content-view version list  --organization="${ORG}"  --content-view CV_Check_MK | awk '/CV_Check_MK/ {print $1}')
# CCVs would contain the RHEL 7 Core Server.
#hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_Server" --composite  --component-ids="${COMP_RHEL7}" --description="Combines RHEL 7 with Basic Core Server"
#hammer content-view publish --name="CCV_RHEL7_Server" --organization="${ORG}" --async

# then run cv_promote.sh

#####################################################################################################################################3
# from here down is probably all extraneous and can be removed after confirming that everything works
#####################################################################################################################################3

# from here down added to other scripts
#hammer product create \
#  --organization ${ORG} \
#  --name EPEL7
#hammer repository update --url 'http://${GATEWAY}/ks/katello-export/${ORG}-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/' --organization redhat --product EPEL7
#hammer repository create --name='EPEL 7 - x86_64' --organization=${ORG} --product='EPEL7' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/
#hammer repository create \
#  --name='EPEL 7 - x86_64' \
#  --organization=${ORG} \
#  --product='EPEL7' \
#  --content-type='yum' \
#  --publish-via-http=true \
#  --url=http://${GATEWAY}/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/
#hammer product create \
#  --organization ${ORG} \
#  --name Check_MK
#chcon -t httpd_sys_content_t apps/check_mk/check-mk-raw-1.4.0p7-el7-54.x86_64.rpm # change selinux context on the repo
#hammer repository create \
#  --name='Check_MK' \
#  --organization=${ORG} \
#  --product='Check_MK' \
#  --content-type='yum' \
#  --publish-via-http=true \
#  --url=http://${GATEWAY}/ks/apps/check_mk
exit 0
