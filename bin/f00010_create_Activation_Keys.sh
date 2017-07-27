#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# What I believe is best practice...
# 1 Lifecycle, content, rhel sub, autoattach (for virt-who)
# 2 group
# 3 custom app
# 4 Layered for ceph, CFME, Satellite that would already have a rhel sub. You would have to isoliate to esxi hosts that do not have rhel subs, other wise you would use a rhel sub and a ceph sub for rhel

# What I did... for now.
# Add a AK for each CCV in each lifecycle. Seems like a good idea.
LIFECYCLE=$(hammer --csv lifecycle-environment list --organization="${ORG}" | sort -n | awk -F"," '{print $1}' | grep -iv ID | grep -v Library)
COMPOSITECONTENTVIEW=$(hammer --csv content-view list --organization="${ORG}" | grep -v "Content View ID,Name,Label,Composite,Repository IDs" | grep true | awk -F"," '{print $2}')

for CCV in "${COMPOSITECONTENTVIEW}";do
  for LE in $(echo "${LIFECYCLE}");do
    hammer activation-key create --name="AK_${LE}_${CCV}" --organization="${ORG}" --lifecycle-environment="${LE}" --content-view="CCV_${CCV}"
    hammer activation-key update --release-version="7Server" --name="AK_${LE}_${CCV}" --organization="${ORG}"
    hammer activation-key add-host-collection --name="AK_${LE}_${CCV}" --organization="${ORG}" --host-collection=HC_"${LE}"_"${CCV}"
  done
done
