#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg
source ../etc/ak_create.cfg

#exec >> ../log/host_create.log 2>&1

#hammer compute-resource list
#--provision-method build \
#--interface="primary=true, \
#            provision=true, \
#            ip=${vmip}" \
#--domain laptop.prayther \
#--compute-attributes="start=true" \
#--subnet "10.0.0.0/24" \
#--compute-profile="1-Small" \
#--ask-root-password no
#--volume="capacity=10G,format_type=qcow2"

vmname="test01"
vmip="10.0.0.10"

hammer host create \
--name "${vmname}" \
--hostgroup HG_Infra_1_Dev_CCV_RHEL7_Server_ORG_redhat_LOC_laptop \
--organization redhat \
--location laptop \
--compute-resource Libvirt_CR \
--compute-profile-id="1"
