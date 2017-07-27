#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

## RHEL 7 basic repos from local for speed, then again later, changing to internet sources to get updated.
hammer organization update --name ${ORG} --redhat-repository-url ${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/
hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer repository-set enable --organization "$ORG" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'

# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put CDN back to redhat and sync latest
hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

#Create a daily sync plan:
hammer sync-plan create --interval=daily --name='Daily' --organization="${ORG}" --sync-date '2017-07-03 24:00:00' --enabled 1
hammer sync-plan list --organization="${ORG}"

#And associate this plan to our products, it must be done by sync-plan-id, not name otherwise hammer doesn't work:
hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Enterprise Linux Server'
