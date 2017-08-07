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

# This is setup for 'all' not just dev. so you get errors so turning off 'run once' with doit
setup_slow_vars () {
                    LE_var=$(hammer --csv lifecycle-environment list --organization="${ORG}" | sort -n | awk -F"," '{print $2}' | grep -iv name | grep -v Library)
                    CCV_var=$(hammer --csv content-view list --organization="${ORG}" | grep -v "Content View ID,Name,Label,Composite,Repository IDs" | grep true | awk -F"," '{print $2}')
                    LOC_var=$(hammer --csv location list | grep -iv id,name | awk -F"," '{print $2}')
                    ORG_var=$(hammer --csv organization list | grep -iv id,name | awk -F"," '{print $2}')
                    NET_var=$(hammer --csv subnet list | grep -vi id,name | awk -F"," '{print $2}')
                    MEDID=$(hammer --csv medium list | grep redhat | awk -F"," '{print $1}')
                    PARTID=$(hammer --csv partition-table list | grep 'Redhat' | cut -d, -f1)
                    OSID=$(hammer --csv os list | awk -F"," '/RedHat ?.?/{print $1}')
	    }
setup_slow_vars

# can't find --content-source-id with a hammer command

hostgroup_create () {
for LOC in $(echo "${LOC_var}");do
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
hostgroup_create

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
