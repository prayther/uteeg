#!/bin/bash -x

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg
source ../etc/enable_rhel.cfg
source ../etc/install-configure-satellite.cfg

exec >> ../log/enable_rhel.log 2>&1

## RHEL 7 basic repos from local for speed, then again changing to internet sources to get updated.
hammer organization update \
  --name ${ORG} \
  --redhat-repository-url ${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/
hammer repository-set enable \
  --organization ${ORG} \
  --product "${PRODUCT}" \
  --basearch="${BASEARCH}" \
  --releasever="${RELEASEVER}" \
  --name "Red Hat Enterprise Linux 7 Server (RPMs)"
hammer repository-set enable \
  --organization ${ORG} \
  --product "${PRODUCT}" \
  --basearch=${BASEARCH} \
  --releasever=${RELEASEVER} \
  --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)"
# can't use releasesever on this one.
#hammer repository-set enable --organization ${ORG} --product 'Red Hat Enterprise Linux Server' --basearch=${BASEARCH} --releasever=${RELEASEVER} --name ${PRODUCT} - Extras (RPMs)'
hammer repository-set enable \
  --organization ${ORG} \
  --product ${PRODUCT} \
  --basearch=${BASEARCH} \
  --name "Red Hat Enterprise Linux 7 Server - Extras (RPMs)"
hammer repository-set enable \
  --organization ${ORG} \
  --product ${PRODUCT} \
  --basearch=${BASEARCH} \
  --releasever=${RELEASEVER} \
  --name "Red Hat Enterprise Linux 7 Server (Kickstart)"
hammer repository-set enable \
  --organization ${ORG} \
  --product ${PRODUCT} \
  --basearch=${BASEARCH} \
  --releasever=${RELEASEVER} \
  --name "Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)"

###########################
#cleanup and add to epel, check_mk
###########################
# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put CDN back to redhat and sync latest
hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

#Create a content view for RHEL 7 Core server x86_64:
hammer content-view create --name='CV_RHEL7_Core' --organization=redhat
for i in $(hammer --csv repository list --organization=redhat | grep "Linux 7 " | grep -v Optional | grep -v Extras | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Core' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
hammer content-view publish --name="CV_RHEL7_Core" --organization=redhat #--async

#Create a content view for RHEL 7 Extras server x86_64:
hammer content-view create --name='CV_RHEL7_Extras' --organization=redhat
for i in $(hammer --csv repository list --organization=redhat | grep "Linux 7 " | grep Extras | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Extras' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
hammer content-view publish --name="CV_RHEL7_Extras" --organization=redhat #--async

#Create a content view for RHEL 7 Optional server x86_64:
hammer content-view create --name='CV_RHEL7_Optional' --organization=redhat
for i in $(hammer --csv repository list --organization=redhat | grep "Linux 7 " | grep Optional | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_RHEL7_Optional' --organization=redhat --repository-id=${i}; done

#Publish the content views to Library:
hammer content-view publish --name="CV_RHEL7_Optional" --organization=redhat #--async


###########################
#cleanup and add to epel, check_mk
###########################
#Create a daily sync plan:
hammer sync-plan create --interval=daily --name='Daily' --organization=redhat --sync-date '2017-07-03 24:00:00' --enabled 1
hammer sync-plan list --organization=redhat

#And associate this plan to our products, it must be done by sync-plan-id, not name otherwise hammer doesn't work:
hammer product set-sync-plan --sync-plan-id=1 --organization=redhat --name='Red Hat Enterprise Linux Server'
#hammer product set-sync-plan --sync-plan-id=1 --organization=redhat --name='Forge'
hammer product set-sync-plan --sync-plan-id=1 --organization=redhat --name='EPEL7'

COMP_RHEL7=$(hammer content-view version list  --organization=redhat  --content-view CV_RHEL7_Core | awk '/CV_RHEL7_Core/ {print $1}')
#COMP_Check_MK=$(hammer content-view version list  --organization=redhat  --content-view CV_Check_MK | awk '/CV_Check_MK/ {print $1}')
# CCVs would contain the RHEL 7 Core Server.
hammer content-view create --organization=redhat --name="CCV_RHEL7_Server" --composite  --component-ids="${COMP_RHEL7}" --description="Combines RHEL 7 with Basic Core Server"
hammer content-view publish --name="CCV_RHEL7_Server" --organization=redhat --async

# then run cv_promote.sh

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

