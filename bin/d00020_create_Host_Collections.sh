#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# Run after creating Content Views and Lifecycles. It use those to create the Host Collections.
# Create a host group for each CCV.

for CV in $(hammer --csv content-view list --organization ${ORG} | sort -n | grep CCV | awk -F"," '{print$2}');do
  for LE in $(hammer --csv lifecycle-environment list --organization ${ORG} | sort -n | awk -F"," '{print $2}' | grep -v "Library" | grep -v "Name");do
    hammer host-collection create --name="HC_${LE}_${CV}" --organization=${ORG}
  done
done
