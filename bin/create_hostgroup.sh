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
#NETNAME='10.0.0.0/24'
# multiple versions of rhel will require whatever u want. latest or multiple
#MEDID=$(hammer --csv medium list | grep redhat | awk -F"," '{print $1}')
# think this is puppet. not using puppet
#ENVID=$(hammer --csv environment list | grep  ANZ_Openshift_Apps_Dev_CCV_Openshift2_1_RHEL6_5_Infra | cut -d, -f1) ; echo $ENVID
#PARTID=$(hammer --csv partition-table list | grep 'Redhat' | cut -d, -f1)
#OSID=$(hammer --csv os list | grep 'RedHat 7.3' | cut -d, -f1)
#CAID=1
#PROXYID=1
#hammer hostgroup create --architecture="x86_64" --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${CCV}" --subnet="${NETNAME}" --ptable-id="${PARTID}" --operatingsystem-id="${OSID}" --puppet-ca-proxy-id="${CAID}" --puppet-proxy-id="${PROXYID}"
#hammer location add-hostgroup --name SA.Demo.ANZ --hostgroup $HGNAME

#for CCV in ${CCV_var};do
#  for LE in ${LE_var};do
#    hammer hostgroup create --architecture="x86_64" --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${LE}_${CCV}" --subnet="${NETNAME}" --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}"
#    hammer organization add-hostgroup --name ${ORG} --hostgroup "HG_${LE}_${CCV}"
#  done
#done

#hammer --csv subnet list
LOC_var="laptop" # could be an array
ORG_var="redhat" # could be an array
NET_var='10.0.0.0/24' # could be an array
MEDID=$(hammer --csv medium list | grep redhat | awk -F"," '{print $1}')
PARTID=$(hammer --csv partition-table list | grep 'Redhat' | cut -d, -f1)
OSID=$(hammer --csv os list | grep 'RedHat 7.3' | cut -d, -f1)

for LOC in ${LOC_var};do
  for ORG in ${ORG_var};do
    for CCV in ${CCV_var};do
      for LE in ${LE_var};do
	for NET in ${NET_var};do
          hammer hostgroup create --architecture="x86_64" --organization "${ORG}" --locations "${LOC}" --lifecycle-environment ${LE} --content-view CCV_${CCV} --content-source-id 9 --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${LE}_${CCV}_${ORG}_${LOC}" --subnet="${NET}" --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}"
          #hammer organization add-hostgroup --name ${ORG} --hostgroup "HG_${LE}_${CCV}"
        done
      done
    done
  done
done
