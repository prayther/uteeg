#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
#source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
#source ../etc/register_cdn.cfg

#exec >> ../log/create_lifecycles.log 2>&1
exec >> ../log/virt_inst.log 2>&1

#Create 3 lifecycle environment paths
#    Openshift Apps -> Dev -> Prod
#    Public_Website -> Dev -> Test -> Prod
#    App -> Dev -> Test -> UAT -> Prod -> Legacy

hammer lifecycle-environment create --name='Infra_1_Dev' --prior='Library' --organization="${ORG}"
hammer lifecycle-environment create --name='Infra_2_Test' --prior='Infra_1_Dev' --organization="${ORG}"
hammer lifecycle-environment create --name='Infra_3_Prod' --prior='Infra_2_Test' --organization="${ORG}"

hammer lifecycle-environment create --name='App_1_Dev' --prior='Library' --organization="${ORG}"
hammer lifecycle-environment create --name='App_2_Test' --prior='App_1_Dev' --organization="${ORG}"
hammer lifecycle-environment create --name='App_3_UAT' --prior='App_2_Test' --organization="${ORG}"
hammer lifecycle-environment create --name='App_4_Prod' --prior='App_3_UAT' --organization="${ORG}"

