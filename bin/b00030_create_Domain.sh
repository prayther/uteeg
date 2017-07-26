#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
#source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
#source ../etc/register_cdn.cfg

#exec >> ../log/virt_inst.log 2>&1
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> ../log/virt-inst.log; done; }
exec 2> >(LOG_)

hammer domain create --locations=${LOC} --organizations=${ORG} --name="${DOMAIN}"
#hammer organization add-domain --domain="${DOMAIN}" --name="${ORG}"
#hammer location add-domain --domain-id=1 --name='BNE.ANZLAB'

