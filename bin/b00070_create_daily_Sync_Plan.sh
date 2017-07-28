#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

#Create a daily sync plan:
hammer sync-plan create --interval=daily --name='Daily' --organization="${ORG}" --sync-date '2017-07-03 24:00:00' --enabled 1
hammer sync-plan list --organization="${ORG}"
