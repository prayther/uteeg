#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

#Create a content view for RHEL 7 Core server x86_64:
hammer content-view create --name='CV_RHEL7_EPEL7' --organization="${ORG}"
for i in $(hammer --csv repository list --organization="${ORG}" | grep EPEL7 | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer content-view add-repository --name='CV_RHEL7_EPEL' --organization="${ORG}" --repository-id="${i}"
done

#Publish the content views to Library:
hammer content-view publish --name="CV_RHEL7_EPEL7" --organization="${ORG}" #--async
