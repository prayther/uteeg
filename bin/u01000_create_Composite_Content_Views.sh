#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

# this script only works with 1.0 version of CV/CCV.

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

doit hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_Core" --composite  --component-ids=$(hammer --csv content-view version list | awk -F"," '/RHEL7_Core/ {print $1}') --description="Combines RHEL 7 with Core Server"
doit hammer content-view publish --name="CCV_RHEL7_Core" --organization="${ORG}" --async

doit hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_Satellite" --composite  --component-ids=$(hammer --csv content-view version list | awk -F"," '/Satellite/ {print $1}' | grep -v Capsule | grep -vi CCV) --description="Combines RHEL 7 with Satellite Server"
doit hammer content-view publish --name="CCV_RHEL7_Satellite" --organization="${ORG}" --async

doit hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_Extras_Optional" --composite  --component-ids=$(hammer --csv content-view version list | grep -vi Library | grep -vi satellite | grep -vi epel | grep -vi CCV | awk -F"," '/RHEL7/ {print $1}' | tr '\n' ' ' | awk '{OFS=","}{print $1, $2, $3}') --description="Combines RHEL 7 with Extras Optional Server"
doit hammer content-view publish --name="CCV_RHEL7_Extras_Optional" --organization="${ORG}" --async

doit hammer content-view create --organization="${ORG}" --name="CCV_RHEL7_EPEL" --composite  --component-ids=$(hammer --csv content-view version list | grep -vi CCV | awk -F"," '/RHEL7_EPEL/ {print $1}') --description="Combines RHEL 7 with EPEL Server"
doit hammer content-view publish --name="CCV_RHEL7_EPEL" --organization="${ORG}" --async

echo "###INFO: Finished $0"
echo "###INFO: $(date)"

# Command notes
#CCV_ALL="CCV_RHEL7_Core CCV_RHEL7_EPEL CCV_RHEL7_Satellite CCV_RHEL7_Extras_Optional"
#[root@sat pulp]# hammer --csv content-view version list  --organization="${ORG}" | sort -t, -k2 | awk -F"," '{print}' | grep Library
#9,CV_RHEL7_Core 2.0,2.0,Library
#16,CV_RHEL7_EPEL 1.0,1.0,Library
#12,CV_RHEL7_Extras 1.0,1.0,Library
#7,CV_RHEL7_Optional 1.0,1.0,Library
#8,CV_RHEL7_Satellite 3.0,3.0,Library
#1,Default Organization View 1.0,1.0,Library
#hammer --csv content-view version list | awk -F"," '/Extras/,/Optional/ {print $1}' | tr '\n' ' ' | awk '{OFS=","}{print $1, $2}'
