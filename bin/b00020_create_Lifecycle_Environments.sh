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

#Create 2 lifecycle environment paths
#Standard Infr stuff
doit hammer lifecycle-environment create --name='Infra_1_Dev' --prior='Library' --organization="${ORG}"
doit hammer lifecycle-environment create --name='Infra_2_Test' --prior='Infra_1_Dev' --organization="${ORG}"
doit hammer lifecycle-environment create --name='Infra_3_Prod' --prior='Infra_2_Test' --organization="${ORG}"
#After Infra stuff goes through release process it's ready for App
doit hammer lifecycle-environment create --name='App_1_Dev' --prior='Library' --organization="${ORG}"
doit hammer lifecycle-environment create --name='App_2_Test' --prior='App_1_Dev' --organization="${ORG}"
doit hammer lifecycle-environment create --name='App_3_UAT' --prior='App_2_Test' --organization="${ORG}"
doit hammer lifecycle-environment create --name='App_4_Prod' --prior='App_3_UAT' --organization="${ORG}"
