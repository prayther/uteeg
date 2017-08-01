#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

# If working on only dev, the other envs error. working well though
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

logfile="../log/$(basename $0 .sh).log"
donefile="../log/$(basename $0 .sh).done"
touch $logfile
touch $donefile

exec > >(tee -a "$logfile") 2>&1

echo "###INFO: Starting $0"
echo "###INFO: $(date)"

# read configuration (needs to be adopted!)
#. ./satenv.sh
source ../etc/virt-inst.cfg


doit() {
        echo "INFO: doit: $@" >&2
        cmd2grep=$(echo "$*" | sed -e 's/\\//' | tr '\n' ' ')
        grep -q "$cmd2grep" $donefile
        if [ $? -eq 0 ] ; then
                echo "INFO: doit: found cmd in donefile - skipping" >&2
        else
                "$@" 2>&1 || {
                        echo "ERROR: cmd was unsuccessfull RC: $? - bailing out" >&2
                        exit 1
                }
                echo "$cmd2grep" >> $donefile
                echo "INFO: doit: cmd finished successfull" >&2
        fi
}

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

LE_var=$(hammer --csv lifecycle-environment list --organization="${ORG}" | sort -n | awk -F"," '{print $2}' | grep -iv name | grep -v Library)
CCV_var=$(hammer --csv content-view list --organization="${ORG}" | grep -v "Content View ID,Name,Label,Composite,Repository IDs" | grep true | awk -F"," '{print $2}')
LOC_var=$(hammer --csv location list | grep -iv id,name | awk -F"," '{print $2}')
ORG_var=$(hammer --csv organization list | grep -iv id,name | awk -F"," '{print $2}')
NET_var=$(hammer --csv subnet list | grep -vi id,name | awk -F"," '{print $2}')
MEDID=$(hammer --csv medium list | grep redhat | awk -F"," '{print $1}')
PARTID=$(hammer --csv partition-table list | grep 'Redhat' | cut -d, -f1)
OSID=$(hammer --csv os list | grep 'RedHat 7.3' | cut -d, -f1)
# can't find --content-source-id with a hammer command

hostgroup_create () { for LOC in $(echo "${LOC_var}");do
  for ORG_local in $(echo "${ORG_var}");do
    for CCV in $(echo "${CCV_var}");do
      for LE in $(echo "${LE_var}");do
        for NET in $(echo "${NET_var}");do
          hammer hostgroup create --root-pass ${PASSWD} --architecture="x86_64" --organization "${ORG_local}" --locations "${LOC}" --lifecycle-environment ${LE} --content-view ${CCV} --content-source-id 1 --domain="${DOMAIN}" --medium-id="${MEDID}" --name="HG_${LE}_${CCV}_ORG_${ORG_local}_LOC_${LOC}" --subnet="${NET}" --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}"
	  hammer hostgroup set-parameter --hostgroup "HG_${LE}_${CCV}_ORG_${ORG_local}_LOC_${LOC}" --value AK_${LE}_${CCV} --name "kt_activation_keys"
        done
      done
    done
  done
done
}
doit hostgroup_create
