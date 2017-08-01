#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

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

# What I believe is best practice...
# 1 Lifecycle, content, rhel sub, autoattach (for virt-who)
# 2 group
# 3 custom app
# 4 Layered for ceph, CFME, Satellite that would already have a rhel sub. You would have to isoliate to esxi hosts that do not have rhel subs, other wise you would use a rhel sub and a ceph sub for rhel

# What I did... for now.
# Add a AK for each CCV in each lifecycle. Seems like a good idea.
LE_var=$(hammer --csv lifecycle-environment list --organization="${ORG}" | sort -n | awk -F"," '{print $2}' | grep -iv name | grep -v Library)
CCV_var=$(hammer --csv content-view list --organization="${ORG}" | grep -v "Content View ID,Name,Label,Composite,Repository IDs" | grep true | awk -F"," '{print $2}')

ak_create () { for CCV in $(echo "${CCV_var}");do
  for LE in $(echo "${LE_var}");do
    hammer activation-key create --name="AK_${LE}_${CCV}" --organization="${ORG}" --lifecycle-environment="${LE}" --content-view="${CCV}"
    hammer activation-key update --release-version="7Server" --name="AK_${LE}_${CCV}" --organization="${ORG}"
    hammer activation-key add-host-collection --name="AK_${LE}_${CCV}" --organization="${ORG}" --host-collection=HC_"${LE}"_"${CCV}"
  done
done
}
doit ak_create
