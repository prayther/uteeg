#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

#Create 2 lifecycle environment paths
#Standard Infr stuff
hammer lifecycle-environment create --name='Infra_1_Dev' --prior='Library' --organization="${ORG}"
hammer lifecycle-environment create --name='Infra_2_Test' --prior='Infra_1_Dev' --organization="${ORG}"
hammer lifecycle-environment create --name='Infra_3_Prod' --prior='Infra_2_Test' --organization="${ORG}"
#After Infra stuff goes through release process it's ready for App
hammer lifecycle-environment create --name='App_1_Dev' --prior='Library' --organization="${ORG}"
hammer lifecycle-environment create --name='App_2_Test' --prior='App_1_Dev' --organization="${ORG}"
hammer lifecycle-environment create --name='App_3_UAT' --prior='App_2_Test' --organization="${ORG}"
hammer lifecycle-environment create --name='App_4_Prod' --prior='App_3_UAT' --organization="${ORG}"

