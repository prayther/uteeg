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
  --name "${PRODUCT} ${KICKSTART}"
hammer repository-set enable \
  --organization ${ORG} \
  --product "${PRODUCT}" \
  --basearch=${BASEARCH} \
  --releasever=${RELEASEVER} \
  --name "${PRODUCT} ${RPMS}"
# can't use releasesever on this one.
#hammer repository-set enable --organization ${ORG} --product 'Red Hat Enterprise Linux Server' --basearch=${BASEARCH} --releasever=${RELEASEVER} --name ${PRODUCT} - Extras (RPMs)'
hammer repository-set enable \
  --organization ${ORG} \
  --product ${PRODUCT} \
  --basearch=${BASEARCH} \
  --name "${PRODUCT} ${EXTRAS}  ${RPMS}"
hammer repository-set enable \
  --organization ${ORG} \
  --product ${PRODUCT} \
  --basearch=${BASEARCH} \
  --releasever=${RELEASEVER} \
  --name "${PRODUCT} ${OPTIONAL} ${RPMS}"
hammer repository-set enable \
  --organization ${ORG} \
  --product ${PRODUCT} \
  --basearch=${BASEARCH} \
  --releasever=${RELEASEVER} \
  --name 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'

# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put CDN back to redhat and sync latest
hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done
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

