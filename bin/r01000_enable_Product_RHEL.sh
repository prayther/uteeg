#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
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

## RHEL 7 basic repos from local for speed, then again later, changing to internet sources to get updated.
curl -f http://"${GATEWAY}"/ks/katello-export && hammer organization update --name ${ORG} --redhat-repository-url ${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/
doit hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
doit hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.3' --name 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7.3'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
#hammer repository-set enable --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
doit hammer repository-set enable --organization "$ORG" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'

# Then we can sync all repositories that we've enable
doit for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer repository synchronize --id ${i} --organization=${ORG}
done

# Put CDN back to redhat and sync latest
doit hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
doit for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer repository synchronize --id ${i} --organization=${ORG}
done

#Create a daily sync plan:
#hammer sync-plan create --interval=daily --name='Daily' --organization="${ORG}" --sync-date '2017-07-03 24:00:00' --enabled 1
#hammer sync-plan list --organization="${ORG}"

#And associate this plan to our products, it must be done by sync-plan-id, not name otherwise hammer doesn't work:
doit hammer product set-sync-plan --sync-plan-id=1 --organization="${ORG}" --name='Red Hat Enterprise Linux Server'

#hammer repository list --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' | grep "7 Server" | grep -vi source | grep -vi iso | grep -vi debug | less
#3  | Red Hat Satellite Tools 6.2 for RHEL 7 Server RPMs x86_64 | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-tools/6....
#2  | Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server     | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os
#13 | Red Hat Enterprise Linux 7 Server RPMs x86_64 7.3         | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/os
#1  | Red Hat Enterprise Linux 7 Server Kickstart x86_64 7.3    | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/kickstart
#hammer repository-set list --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' | grep "7 Server" | grep -vi source | grep -vi iso | grep -vi debug | less
#4380 | yum       | Red Hat Satellite Tools 6 Beta (for RHEL 7 Server) (RPMs)
#4922 | yum       | Red Hat Ceph Storage Tools 2 for Red Hat Enterprise Linux 7 Server (RPMs)
#5091 | yum       | Red Hat Insights Client 1 (for RHEL 7 Server) (RPMs)
#5726 | yum       | Red Hat OpenStack Platform 11 Tools for RHEL 7 Server (RPMs)
#2460 | yum       | Red Hat Enterprise Linux 7 Server - Fastrack (RPMs)
#2480 | yum       | Red Hat Enterprise Linux 7 Server - Supplementary Beta (RPMs)
#4725 | yum       | Red Hat OpenStack Platform 8 Tools for RHEL 7 Server (RPMs)
#4831 | yum       | Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)
#2484 | yum       | Red Hat Enterprise Linux 7 Server Beta (RPMs)
#4539 | yum       | Red Hat OpenStack Tools 7.0 for Red Hat Enterprise Linux 7 Server (RPMs)
#2463 | yum       | Red Hat Enterprise Linux 7 Server - Optional (RPMs)
#2466 | yum       | Red Hat Enterprise Linux 7 Server - Optional Beta (RPMs)
#2455 | kickstart | Red Hat Enterprise Linux 7 Server (Kickstart)
#3030 | yum       | Red Hat Enterprise Linux 7 Server - Extras (RPMs)
#6011 | yum       | Red Hat Enterprise Linux 7 Server - Extras Beta (RPMs)
#4188 | yum       | Red Hat Satellite Tools 6.1 (for RHEL 7 Server) (RPMs)
#5362 | yum       | Red Hat Satellite Tools 6.3 (for RHEL 7 Server) (RPMs)
#5916 | yum       | Red Hat OpenStack Platform 12 Tools for RHEL 7 Server (RPMs)
#3950 | kickstart | Red Hat Enterprise Linux 7 Server Beta (Kickstart)
#5064 | yum       | Red Hat OpenStack Platform 10 Tools for RHEL 7 Server (RPMs)
#2472 | yum       | Red Hat Enterprise Linux 7 Server - RH Common (RPMs)
#2469 | yum       | Red Hat Enterprise Linux 7 Server - Optional Fastrack (RPMs)
#5996 | yum       | Red Hat Satellite Maintenance 6 (for RHEL 7 Server) (RPMs)
#5048 | yum       | Red Hat OpenStack Platform 9 Tools for RHEL 7 Server (RPMs)
#2456 | yum       | Red Hat Enterprise Linux 7 Server (RPMs)
#3327 | yum       | RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)
#3512 | yum       | Red Hat Enterprise Linux 7 Server - RH Common Beta (RPMs)
#2476 | yum       | Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)
#4455 | yum       | Red Hat Ceph Storage Tools 1.3 for Red Hat Enterprise Linux 7 Server (RPMs)
#3331 | yum       | RHN Tools for Red Hat Enterprise Linux 7 Server Beta (RPMs)