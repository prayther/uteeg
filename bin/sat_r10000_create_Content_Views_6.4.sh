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

#Create a content view for RHEL 7 Core server x86_64:
hammer content-view create --name='CV_RHEL7_Core' --organization="${ORG}"
#repolistrhel() { for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep -v Optional | grep -v Extras | awk -F, {'print $1'})
repolistrhel() { for i in $(hammer --csv repository list --organization="${ORG}" | grep -v EPEL | grep -v "Red Hat Satellite Capsule" | grep -v "Red Hat Satellite 6.4" | grep -v Collections | grep -v Optional | grep -v Extras | grep -v Kickstart | awk -F, {'print $1'} | grep -v Id | sort -n)
  do hammer content-view add-repository --name='CV_RHEL7_Core' --organization="${ORG}" --repository-id=${i}
done
}
repolistrhel

#Create a content view for Satellite
hammer content-view create --name='CV_RHEL7_Satellite' --organization="${ORG}"
#repolistsat () {  for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep Satellite | grep -v Tools | grep -vi Capsule | awk -F"," '{print $1}')
repolistsat () {  for i in $(hammer --csv repository list --organization="${ORG}" | grep -v EPEL | grep -v "Red Hat Satellite Capsule" | grep -v Optional | grep -v Extras | grep -v Kickstart | awk -F, {'print $1'} | grep -v Id | sort -n)
  do hammer content-view add-repository --name='CV_RHEL7_Satellite' --organization="${ORG}" --repository-id=${i}
done
}
repolistsat

#adding tools for katello-agent
#repolistsat1 () { for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep Tools | awk -F, {'print $1'})
#  do hammer content-view add-repository --name='CV_RHEL7_Satellite' --organization="${ORG}" --repository-id=${i}
#done
#}
#repolistsat1

#Create a content view for RHEL 7 Satellite Capsule server x86_64:
hammer content-view create --name='CV_RHEL7_Satellite_Capsule' --organization="${ORG}"
#repolistcap () {  for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep Satellite | grep -v Tools | grep  Capsule | awk -F"," '{print $1}')
repolistcap () {  for i in $(hammer --csv repository list --organization="${ORG}" | grep -v EPEL | grep -v "Red Hat Satellite 6.4" | grep -v Optional | grep -v Extras | grep -v Kickstart | awk -F, {'print $1'} | grep -v Id | sort -n)
  do hammer content-view add-repository --name='CV_RHEL7_Satellite_Capsule' --organization="${ORG}" --repository-id=${i}
done
}
repolistcap

#adding tools for katello-agent
#repolistcap1() { for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep Tools | awk -F, {'print $1'})
#  do hammer content-view add-repository --name='CV_RHEL7_Satellite_Capsule' --organization="${ORG}" --repository-id=${i}
#done
#}
#repolistcap1

#Create a content view for RHEL 7 EXTRAS_OPTIONA_EPEL x86_64:
hammer content-view create --name='CV_RHEL7_Extras_Optional_EPEL' --organization="${ORG}"
#repolistextras() { for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep -v Optional | grep Extras | grep -vi EPEL7 | awk -F, {'print $1'})
repolistextras() { for i in $(hammer --csv repository list --organization="${ORG}" | grep -v Kickstart | grep -v Collections | grep -v "Red Hat Satellite 6.4" | grep -v "Red Hat Satellite Capsule" | awk -F, {'print $1'} | grep -v Id | sort -n)
  do hammer content-view add-repository --name='CV_RHEL7_Extras_Optional_EPEL' --organization="${ORG}" --repository-id="${i}"
done
}
repolistextras

#adding tools for katello-agent
#repolistextas1 () { for i in $(hammer --csv repository list --organization="${ORG}" | grep "7 Server" | grep Tools | awk -F, {'print $1'})
#  do hammer content-view add-repository --name='CV_RHEL7_Extras' --organization="${ORG}" --repository-id=${i}
#done
#}
#repolistextras1


#Publish the content views to Library:
#hammer content-view publish --name="CV_RHEL7_Satellite" --organization="${ORG}" #--async
publishcv() {
	for i in $(hammer --csv content-view list --organization="${ORG}" | grep -v Default | grep -v ID | awk -F, {'print $2'})
		do hammer content-view publish --name="${i}" --organization="${ORG}" #--async
	done
}
publishcv

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
