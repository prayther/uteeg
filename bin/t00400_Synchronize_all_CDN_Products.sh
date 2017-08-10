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

#hammer organization update --name redhat --redhat-repository-url ${CDN_URL}
# Synchronize all Products
synchronize_all () { for i in $(hammer --csv repository list --organization=${ORG} | grep -vi EPEL | awk -F, {'print $1'} | grep -vi '^ID' | sort -n)
  do hammer repository synchronize --id ${i} --organization=${ORG} --async
done
}
doit synchronize_all

# async everything, but wait till all done
	#for repo_list in $(hammer --csv repository list --organization=${ORG}| awk -F"," '!/Id/{print $1}')
	#  do while [[ ! $(hammer repository  info --id="${repo_list}"| grep Status | grep Success) ]];do sleep 30; echo "repo ${repo_list} is still syncing";done
        #done
wait_till_done () {
        while [[ $(hammer --csv task list | grep -v stopped | grep Synchronize) ]];do sleep 30; echo "Repo is still syncing";done
}
wait_till_done

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
