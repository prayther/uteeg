#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

hammer subnet create --locations=${LOC} --organizations=${ORG} --domains="${DOMAIN}" --gateway='10.0.0.1' --mask='255.255.255.0' --name='10.0.0.0/24'  --tftp-id=1 --network='10.0.0.0' --boot-mode="Static" --ipam="None" --dns-primary="${GATEWAY}"
# add the subnet to the org
hammer organization add-subnet --subnet="${NAME}" --name="${ORG}"
