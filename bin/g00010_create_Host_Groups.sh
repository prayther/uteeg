#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

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

#LE_var and CCV_var are sourced in virt-inst.cfg because they are used in at least 2 scripts
LOC_var=$(hammer --csv location list | grep -iv id,name | awk -F"," '{print $2}')
ORG_var=$(hammer --csv organization list | grep -iv id,name | awk -F"," '{print $2}')
NET_var=$(hammer --csv subnet list | grep -vi id,name | awk -F"," '{print $2}')
MEDID=$(hammer --csv medium list | grep redhat | awk -F"," '{print $1}')
PARTID=$(hammer --csv partition-table list | grep 'Redhat' | cut -d, -f1)
OSID=$(hammer --csv os list | grep 'RedHat 7.3' | cut -d, -f1)
# can't find --content-source-id with a hammer command

for LOC in $(echo "${LOC_var}");do
  for ORG_local in $(echo "${ORG_var}");do
    for CCV in $(echo "${CCV_var}");do
      for LE in $(echo "${LE_var}");do
        for NET in $(echo "${NET_var}");do
          hammer hostgroup create --root-pass ${PASSWD} --architecture="x86_64" --organization "${ORG_local}" --locations "${LOC}" --lifecycle-environment ${LE} --content-view CCV_${CCV} --content-source-id 1 --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${LE}_CCV_${CCV}_ORG_${ORG_local}_LOC_${LOC}" --subnet="${NET}" --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}"
	  hammer hostgroup set-parameter --hostgroup "HG_${LE}_CCV_${CCV}_ORG_${ORG_local}_LOC_${LOC}" --value AK_${LE}_${CCV} --name "kt_activation_keys"
        done
      done
    done
  done
done
