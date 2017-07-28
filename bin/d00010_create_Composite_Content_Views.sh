#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

RHEL7_Core=$(hammer --csv content-view version list  --organization="${ORG}"  --content-view CV_RHEL7_Core | awk '/CV_RHEL7_Core/ {print $1}')
hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_Server" --composite  --component-ids="${RHEL7_Core}" --description="Combines RHEL 7 with Basic Core Server"
hammer content-view publish --name="CCV_RHEL7_Server" --organization="${ORG}" --async

RHEL7_EPEL=$(hammer --csv content-view version list  --organization="${ORG}"  --content-view="CV_RHEL7_EPEL" | awk '/CV_RHEL7_Core/ {print $1}')
hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_EPEL" --composite  --component-ids="${RHEL7_EPEL}" --description="Combines RHEL 7 with EPEL"
hammer content-view publish --name="CCV_RHEL7_EPEL" --organization="${ORG}" --async

