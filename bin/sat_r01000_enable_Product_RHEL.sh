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

# Enable RHEl core
doit hammer repository-set enable --organization="${ORG}" --new-name="${RHELKS}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7.4' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
doit hammer repository-set enable --organization="${ORG}" --new-name="${RHEL}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
doit hammer repository-set enable --organization="$ORG" --new-name="${TOOLS}" --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)'

# Then we can sync all repositories that we've enable
#repo_sync () { for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID')
#  do hammer repository synchronize --id ${i} --organization=${ORG}
#done
#}
#repo_sync

echo "###INFO: Finished $0"
echo "###INFO: $(date)"

# Command notes
#hammer repository list --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' | grep "7 Server" | grep -vi source | grep -vi iso | grep -vi debug | less
#3  | Red Hat Satellite Tools 6.2 for RHEL 7 Server RPMs x86_64 | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-tools/6....
#2  | Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server     | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os
#13 | Red Hat Enterprise Linux 7 Server RPMs x86_64 7.3         | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/os
#1  | Red Hat Enterprise Linux 7 Server Kickstart x86_64 7.3    | Red Hat Enterprise Linux Server | yum          | https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/kickstart
#hammer repository-set list --organization "${ORG}" --product 'Red Hat Enterprise Linux Server' | grep "7 Server" | grep -vi source | grep -vi iso | grep -vi debug | less

#4743 | Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)
#4751 | Red Hat Satellite Capsule 6.2 (for RHEL 7 Server) (RPMs)
#2808 | Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server

#2455 | Red Hat Enterprise Linux 7 Server (Kickstart)
#2456 | Red Hat Enterprise Linux 7 Server (RPMs)
#2460 | Red Hat Enterprise Linux 7 Server - Fastrack (RPMs)
#2463 | Red Hat Enterprise Linux 7 Server - Optional (RPMs)
#2469 | Red Hat Enterprise Linux 7 Server - Optional Fastrack (RPMs)
#2472 | Red Hat Enterprise Linux 7 Server - RH Common (RPMs)
#2476 | Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)
#3030 | Red Hat Enterprise Linux 7 Server - Extras (RPMs)
#3327 | RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)
#4188 | Red Hat Satellite Tools 6.1 (for RHEL 7 Server) (RPMs)
#4455 | Red Hat Ceph Storage Tools 1.3 for Red Hat Enterprise Linux 7 Server (RPMs)
#4539 | Red Hat OpenStack Tools 7.0 for Red Hat Enterprise Linux 7 Server (RPMs)
#4725 | Red Hat OpenStack Platform 8 Tools for RHEL 7 Server (RPMs)
#4831 | Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)
#4922 | Red Hat Ceph Storage Tools 2 for Red Hat Enterprise Linux 7 Server (RPMs)
#5048 | Red Hat OpenStack Platform 9 Tools for RHEL 7 Server (RPMs)
#5064 | Red Hat OpenStack Platform 10 Tools for RHEL 7 Server (RPMs)
#5091 | Red Hat Insights Client 1 (for RHEL 7 Server) (RPMs)
#5362 | Red Hat Satellite Tools 6.3 (for RHEL 7 Server) (RPMs)
#5726 | Red Hat OpenStack Platform 11 Tools for RHEL 7 Server (RPMs)
#5916 | Red Hat OpenStack Platform 12 Tools for RHEL 7 Server (RPMs)
#5996 | Red Hat Satellite Maintenance 6 (for RHEL 7 Server) (RPMs)

