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

hammer product create --name='Containers' --organization="${ORG}"
hammer repository create --name='rhel' --organization="${ORG}" --product='Containers' --content-type='docker' --url='https://registry.access.redhat.com' --docker-upstream-name='rhel' --publish-via-http="true"
hammer product synchronize --organization="${ORG}" --name='Containers'

hammer content-view create --organization="${ORG}" --name "Production Registry" --description "Production Registry"
hammer content-view add-repository --organization="${ORG}" --name "Production Registry" --repository "rhel" --product "Containers"
hammer content-view publish --organization="${ORG}" --name "Production Registry"

for i in Infra_1_Dev App_1_Dev 
  do hammer content-view version promote --organization="${ORG}" --to-lifecycle-environment="${i}" --content-view "Production Registry" --async
done
#hammer content-view version promote --organization="${ORG}" --to-lifecycle-environment QA --content-view "Production Registry" --async
#hammer content-view version promote --organization="${ORG}" --to-lifecycle-environment Production --content-view "Production Registry" --async


echo "###INFO: Finished $0"
echo "###INFO: $(date)"
