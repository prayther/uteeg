#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg
source ../etc/ak_create.cfg

#exec >> ../log/hc_create.log 2>&1

# Create Host Collections
# RHEL
# Lifecycle
# App

# Run after creating Content Views and Lifecycles. It uses those to create the Host Collections.
# Create a host group for each CCV.

for CV in $(hammer --csv content-view list --organization ${ORG} | sort -n | grep CCV | awk -F"," '{print$2}' | sed 's/^[^_]*_//g');do
  for LE in $(hammer --csv lifecycle-environment list --organization ${ORG} | sort -n | awk -F"," '{print $2}' | grep -v "Library" | grep -v "Name");do
    hammer host-collection create --name="HC_${LE}_${CV}" --organization=${ORG}
  done
done




