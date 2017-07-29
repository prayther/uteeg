#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

## RHEL 7 basic repos from local for speed, then again later, changing to internet sources to get updated.
curl -f http://"${GATEWAY}"/ks/katello-export/ && hammer organization update --name ${ORG} --redhat-repository-url http://"${GATEWAY}"/ks/katello-export/
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7.3'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
#hammer repository-set enable --organization "$ORG" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'
hammer repository-set enable --organization "$ORG" --product 'Red Hat Satellite' --basearch='x86_64' --name 'Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)'
hammer repository-set enable --organization "$ORG" --product 'Red Hat Software Collections for RHEL Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server'
hammer repository-set enable --organization "$ORG" --product 'Red Hat Satellite Capsule' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Satellite Capsule 6.2 (for RHEL 7 Server) (RPMs)'

# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put CDN back to redhat and sync latest
hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

#Create a daily sync plan:
#hammer sync-plan create --interval=daily --name='Daily' --organization="${ORG}" --sync-date '2017-07-03 24:00:00' --enabled 1
#hammer sync-plan list --organization="${ORG}"

#And associate this plan to our products, it must be done by sync-plan-id, not name otherwise hammer doesn't work:
#hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Enterprise Linux Server'
hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Software Collections for RHEL Server'
hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Satellite'
hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Satellite Capsule'

#[root@sat pulp]# hammer product list --organization-id 1 | grep atellite
#12 | Red Hat Satellite Capsule                                                        |             | redhat       | 1            |
#30 | Red Hat Satellite                                                                |             | redhat       | 1            |
#11 | Red Hat Software Collections for RHEL Server                                     |             | redhat       | 1            |
#28 | Red Hat Enterprise Linux Server                                                  |             | redhat       | 6            |


#[root@sat pulp]# hammer repository-set list --product-id 30 | grep "Satellite 6.2"
#4743 | yum  | Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)
#ID   | TYPE | NAME
#-----|------|---------------------------------------------------------------------------
#4751 | yum  | Red Hat Satellite Capsule 6.2 (for RHEL 7 Server) (RPMs)
#4743 | yum  | Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)
#2808,yum,Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server
#3815 | yum       | Red Hat Virt V2V Tool for RHEL 7 (RPMs)
#4922 | yum       | Red Hat Ceph Storage Tools 2 for Red Hat Enterprise Linux 7 Server (RPMs)
#5091 | yum       | Red Hat Insights Client 1 (for RHEL 7 Server) (RPMs)
#5726 | yum       | Red Hat OpenStack Platform 11 Tools for RHEL 7 Server (RPMs)
#2460 | yum       | Red Hat Enterprise Linux 7 Server - Fastrack (RPMs)
#4725 | yum       | Red Hat OpenStack Platform 8 Tools for RHEL 7 Server (RPMs)
#4831 | yum       | Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)
#4539 | yum       | Red Hat OpenStack Tools 7.0 for Red Hat Enterprise Linux 7 Server (RPMs)
#2463 | yum       | Red Hat Enterprise Linux 7 Server - Optional (RPMs)
#2455 | kickstart | Red Hat Enterprise Linux 7 Server (Kickstart)
#3030 | yum       | Red Hat Enterprise Linux 7 Server - Extras (RPMs)
#4188 | yum       | Red Hat Satellite Tools 6.1 (for RHEL 7 Server) (RPMs)
#5916 | yum       | Red Hat OpenStack Platform 12 Tools for RHEL 7 Server (RPMs)
#5064 | yum       | Red Hat OpenStack Platform 10 Tools for RHEL 7 Server (RPMs)
#2472 | yum       | Red Hat Enterprise Linux 7 Server - RH Common (RPMs)
#2469 | yum       | Red Hat Enterprise Linux 7 Server - Optional Fastrack (RPMs)
#5996 | yum       | Red Hat Satellite Maintenance 6 (for RHEL 7 Server) (RPMs)
#5048 | yum       | Red Hat OpenStack Platform 9 Tools for RHEL 7 Server (RPMs)
#2456 | yum       | Red Hat Enterprise Linux 7 Server (RPMs)
#3327 | yum       | RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)
#2476 | yum       | Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)
#4455 | yum       | Red Hat Ceph Storage Tools 1.3 for Red Hat Enterprise Linux 7 Server (RPMs)
#4562 | yum       | Red Hat Storage Native Client for RHEL 7 (RPMs)
#-----|-----------|---------------------------------------------------------------------------------


