#!/bin/bash -x

cd "${BASH_SOURCE%/*}"
source ../etc/ak_create.cfg 

# Create Activation Keys.
# This script will run after cv create, lifecycle create, cv_promote.sh
#hammer activation-key create \
# --name='AK_Infra_Dev' \
# --organization=redhat \
# --content-view='CCV_RHEL7_Server' \
# --lifecycle-environment='Infra_Dev' \

# 1 Lifecycle, content, rhel sub, autoattach (for virt-who)
# 2 group
# 3 custom app
# 4 Layered for ceph, CFME, Satellite that would already have a rhel sub. You would have to isoliate to esxi hosts that do not have rhel subs, other wise you would use a rhel sub and a ceph sub for rhel

# Add a AK for each CCV. Seems like a good idea.
#for CCV in $(hammer --csv content-view list --organization redhat | grep CCV | awk -F"," '{print$2}' | sed 's/^[^_]*_//g');do
#  for LE in $(hammer --csv lifecycle-environment list --organization redhat | awk -F"," '{print $2}' | grep -v "Library" | grep -v "Name");do
for CCV in ${CCV_var};do
  for LE in ${LE_var};do
    hammer activation-key create --name "AK_${LE}_${CCV}" --organization=redhat --lifecycle-environment ${LE} --content-view CCV_${CCV}
    hammer activation-key add-host-collection --name "AK_${LE}_${CCV}" --organization=redhat --host-collection HC_${LE}_${CCV}
  done
done
