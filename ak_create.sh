#!/bin/bash -x

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

# This first piece works. Now add the rest
for CCV in $(hammer --csv content-view list --organization redhat | grep CCV | awk -F"," '{print$2}' | sed 's/^[^_]*_//g');do
  for LE in $(hammer --csv lifecycle-environment list --organization redhat | awk -F"," '{print $2}' | grep -v "Library" | grep -v "Name");do
    hammer activation-key create --name "AK_${LE}_${CCV}" --organization=redhat --lifecycle-environment ${LE} --content-view CCV_${CCV}
  done
done

# hammer activation-key --help
#Usage:
#    hammer activation-key [OPTIONS] SUBCOMMAND [ARG] ...
#
#Parameters:
# SUBCOMMAND                    subcommand
# [ARG] ...                     subcommand arguments
#
#Subcommands:
# add-host-collection           Associate a resource
# add-subscription              Add subscription
# content-override              Override product content defaults
# copy                          Copy an activation key
# create                        Create an activation key
# delete                        Destroy an activation key
# host-collections              List associated host collections
# info                          Show an activation key
# list                          List activation keys
# product-content               List associated products
# remove-host-collection        Disassociate a resource
# remove-subscription           Remove subscription
# subscriptions                 List associated subscriptions
# update                        Update an activation key
