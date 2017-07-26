#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg

#exec >> ../log/virt_inst.log 2>&1
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> ../log/virt-inst.log; done; }
exec 2> >(LOG_)

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




