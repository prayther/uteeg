#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# Setup EPEL
hammer product create --organization ${ORG} --name=RHEL7_EPEL7

curl -f http://"${GATEWAY}/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/" && hammer repository create --name=RHEL7_EPEL --organization=${ORG} --product=RHEL7_EPEL --content-type='yum' --publish-via-http=true --url=http://${GATEWAY}/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/
# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "RHEL7_EPEL" | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer repository synchronize --id ${i} --organization=${ORG}
done

# Put pulic mirror back to sync latest
hammer repository update --url ${URL_EPEL} --organization "${ORG}" --product EPEL7
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "RHEL7_EPEL" | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer repository synchronize --id ${i} --organization=${ORG}
done
