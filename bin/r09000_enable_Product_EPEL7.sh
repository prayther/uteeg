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

# Setup EPEL
doit hammer product create --organization ${ORG} --name=RHEL7_EPEL7

curl -f http://"${GATEWAY}/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/" && hammer repository create --name=RHEL7_EPEL --organization=${ORG} --product=RHEL7_EPEL --content-type='yum' --publish-via-http=true --url=http://${GATEWAY}/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/
# Then we can sync all repositories that we've enable
repolist () { for i in $(hammer --csv repository list --organization=${ORG} | grep -i "RHEL7_EPEL" | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer repository synchronize --id ${i} --organization=${ORG}
done
}
doit repolist

# Put pulic mirror back to sync latest
hammer repository update --url ${URL_EPEL} --organization "${ORG}" --product="RHEL7_EPEL7"
#for i in $(hammer --csv repository list --organization=${ORG} | grep -i "RHEL7_EPEL" | awk -F, {'print $1'} | grep -vi '^ID')
#  do hammer repository synchronize --id ${i} --organization=${ORG}
#done
doit repolist