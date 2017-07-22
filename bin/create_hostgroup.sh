#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg
source ../etc/ak_create.cfg

#exec >> ../log/create_hostgroup.log 2>&1
#HGNAME="HG_Openshift_Hosts_Infra_Dev"
NETNAME='10.0.0.0/24'
# multiple versions of rhel will require whatever u want. latest or multiple
MEDID=$(hammer --csv medium list | grep redhat | awk -F"," '{print $1}')
# think this is puppet. not using puppet
#ENVID=$(hammer --csv environment list | grep  ANZ_Openshift_Apps_Dev_CCV_Openshift2_1_RHEL6_5_Infra | cut -d, -f1) ; echo $ENVID
PARTID=$(hammer --csv partition-table list | grep 'Redhat' | cut -d, -f1)
OSID=$(hammer --csv os list | grep 'RedHat 7.3' | cut -d, -f1)
#CAID=1
#PROXYID=1
#hammer hostgroup create --architecture="x86_64" --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${CCV}" --subnet="${NETNAME}" --ptable-id="${PARTID}" --operatingsystem-id="${OSID}" --puppet-ca-proxy-id="${CAID}" --puppet-proxy-id="${PROXYID}"
#hammer location add-hostgroup --name SA.Demo.ANZ --hostgroup $HGNAME

for CCV in ${CCV_var};do
  for LE in ${LE_var};do
    #hammer activation-key create --name "AK_${LE}_${CCV}" --organization=${ORG} --lifecycle-environment ${LE} --content-view CCV_${CCV}
    #hammer activation-key add-host-collection --name "AK_${LE}_${CCV}" --organization=${ORG} --host-collection HC_${LE}_${CCV}
    hammer hostgroup create --architecture="x86_64" --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${LE}_${CCV}" --subnet="${NETNAME}" --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}"
  done
done

