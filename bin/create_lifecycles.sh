#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg

exec >> ../log/create_lifecycles.log 2>&1

#Create 3 lifecycle environment paths
#    Openshift Apps -> Dev -> Prod
#    Public_Website -> Dev -> Test -> Prod
#    App -> Dev -> Test -> UAT -> Prod -> Legacy

hammer lifecycle-environment create --name='1_Infra_Dev' --prior='Library' --organization="${ORG}"
hammer lifecycle-environment create --name='2_Infra_Test' --prior='1_Infra_Dev' --organization="${ORG}"
hammer lifecycle-environment create --name='3_Infra_Prod' --prior='2_Infra_Test' --organization="${ORG}"

hammer lifecycle-environment create --name='1_App_Dev' --prior='Library' --organization="${ORG}"
hammer lifecycle-environment create --name='2_App_Test' --prior='1_App_Dev' --organization="${ORG}"
hammer lifecycle-environment create --name='3_App_UAT' --prior='2_App_Test' --organization="${ORG}"
hammer lifecycle-environment create --name='4_App_Prod' --prior='3_App_UAT' --organization="${ORG}"

