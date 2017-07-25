#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
#source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
#source ../etc/register_cdn.cfg
#source ../etc/ak_create.cfg

#exec >> ../log/create_ccv.log 2>&1
exec >> ../log/virt_inst.log 2>&1

COMP_RHEL7=$(hammer content-view version list  --organization="${ORG}"  --content-view CV_RHEL7_Core | awk '/CV_RHEL7_Core/ {print $1}')
#COMP_Check_MK=$(hammer content-view version list  --organization="${ORG}"  --content-view CV_Check_MK | awk '/CV_Check_MK/ {print $1}')
# CCVs would contain the RHEL 7 Core Server.
hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_Server" --composite  --component-ids="${COMP_RHEL7}" --description="Combines RHEL 7 with Basic Core Server"
hammer content-view publish --name="CCV_RHEL7_Server" --organization="${ORG}" --async

