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

# Enable stuff for Satellite
#setup_slow_vars () {
#                    Satellite_Label=$(hammer --csv activation-key product-content --name "AK_Infra_1_Dev_CCV_RHEL7_Satellite" --organization="${ORG}" | awk -F"," '/rhel-7-server-satellite-6.2-rpms/{print $6}')
#                    AK_Id=$(hammer --csv activation-key list --organization="${ORG}" | awk -F"," '/AK_Infra_1_Dev_CCV_RHEL7_Satellite/{print $1}')
#	    }
#setup_slow_vars
#hammer activation-key content-override --content-label="${Satellite_Label}" --id="${AK_Id}" --value 1
#
## Enable stuff for rhscl
#setup_slow_vars1 () {
#                     RHSCL_Label=$(hammer --csv activation-key product-content --name "AK_Infra_1_Dev_CCV_RHEL7_Satellite" --organization="${ORG}" | awk -F"," '/rhel-server-rhscl-7-rpms/{print $6}')
#	     }
#setup_slow_vars1
#hammer activation-key content-override --content-label="${RHSCL_Label}" --id="${AK_Id}" --value 1
#
## Enable stuff for tools
#setup_slow_vars2 () {
#                     Tools_Label=$(hammer --csv activation-key product-content --name "AK_Infra_1_Dev_CCV_RHEL7_Satellite" --organization="${ORG}" | awk -F"," '/rhel-7-server-satellite-tools-6.2-rpms/{print $6}')
#	     }
#setup_slow_vars2
#hammer activation-key content-override --content-label="${Tools_Label}" --id="${AK_Id}" --value 1

#AK Activation Key
#CL Content Label
content_overide_rhel() {
	for AK_Id in $(hammer --csv activation-key list --organization="${ORG}" | grep Core | awk -F"," '{print $1}' | sort -n);do
		for CL in $(hammer --csv activation-key product-content --id="${AK_Id}" --organization="${ORG}" | grep Tools | awk -F"," '{print $6}');do
                hammer activation-key content-override --content-label="${CL}" --id="${AK_Id}" --value 1
                done
        done
}
content_overide_rhel

content_overide_extras_optional_epel() {
        for AK_Id in $(hammer --csv activation-key list --organization="${ORG}" | grep Extras | awk -F"," '{print $1}' | sort -n);do
		for CL in $(hammer --csv activation-key product-content --id="${AK_Id}" --organization="${ORG}" | grep -v satellite-6.2 | grep -v Capsule | grep -v Collections | grep -v ID | grep -v Kickstart | awk -F"," '{print $6}');do
                hammer activation-key content-override --content-label="${CL}" --id="${AK_Id}" --value 1
                done
        done
}
content_overide_extras_optional_epel

content_overide_sat() {
	    for AK_Id in $(hammer --csv activation-key list --organization="${ORG}" | grep Satellite | grep -v Capsule | awk -F"," '{print $1}' | sort -n);do
		for CL in $(hammer --csv activation-key product-content --id="${AK_Id}" --organization="${ORG}" | grep -v Label | grep -v EPEL | grep -v Optional | grep -v Extras | grep -v Capsule | grep -v Kickstart | awk -F"," '{print $6}');do
		hammer activation-key content-override --content-label="${CL}" --id="${AK_Id}" --value 1
		done
	done
}
content_overide_sat

content_overide_satcap() {
            for AK_Id in $(hammer --csv activation-key list --organization="${ORG}" | grep Capsule | awk -F"," '{print $1}' | sort -n);do
		    for CL in $(hammer --csv activation-key product-content --id="${AK_Id}" --organization="${ORG}" | grep -v Label | grep -v EPEL | grep -v Optional | grep -v Extras | grep -v Kickstart | grep -v satellite-6.2 | awk -F"," '{print $6}');do
                hammer activation-key content-override --content-label="${CL}" --id="${AK_Id}" --value 1
                done
            done
}
content_overide_satcap

echo "###INFO: Finished $0"
echo "###INFO: $(date)"

# Command notes
#[root@sat log]# hammer activation-key list --organization redhat
#---|------------------------------------------|----------------|-----------------------|--------------------------
#ID | NAME                                     | HOST LIMIT     | LIFECYCLE ENVIRONMENT | CONTENT VIEW
#---|------------------------------------------|----------------|-----------------------|--------------------------
#1  | AK_Infra_1_Dev_CCV_RHEL7_Satellite       | 1 of Unlimited | Infra_1_Dev           | CCV_RHEL7_Satellite
#3  | AK_Infra_1_Dev_CCV_RHEL7_Extras_Optional | 0 of Unlimited | Infra_1_Dev           | CCV_RHEL7_Extras_Optional
#5  | AK_Infra_1_Dev_CCV_RHEL7_EPEL            | 0 of Unlimited | Infra_1_Dev           | CCV_RHEL7_EPEL
#7  | AK_Infra_1_Dev_CCV_RHEL7_Core            | 0 of Unlimited | Infra_1_Dev           | CCV_RHEL7_Core
#2  | AK_App_1_Dev_CCV_RHEL7_Satellite         | 0 of Unlimited | App_1_Dev             | CCV_RHEL7_Satellite
#4  | AK_App_1_Dev_CCV_RHEL7_Extras_Optional   | 0 of Unlimited | App_1_Dev             | CCV_RHEL7_Extras_Optional
#6  | AK_App_1_Dev_CCV_RHEL7_EPEL              | 0 of Unlimited | App_1_Dev             | CCV_RHEL7_EPEL
#8  | AK_App_1_Dev_CCV_RHEL7_Core              | 0 of Unlimited | App_1_Dev             | CCV_RHEL7_Core
#---|------------------------------------------|----------------|-----------------------|--------------------------

#[root@sat log]# hammer activation-key product-content --name "AK_Infra_1_Dev_CCV_RHEL7_Satellite" --organization redhat
#-----|-------------------------------------------------------------------------|------|-----|---------|------------------------------------------|---------
#ID   | NAME                                                                    | TYPE | URL | GPG KEY | LABEL                                    | ENABLED?
#-----|-------------------------------------------------------------------------|------|-----|---------|------------------------------------------|---------
#2808 | Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server |      |     |         | rhel-server-rhscl-7-rpms                 | default
#4751 | Red Hat Satellite Capsule 6.2 (for RHEL 7 Server) (RPMs)                |      |     |         | rhel-7-server-satellite-capsule-6.2-rpms | default
#4743 | Red Hat Satellite 6.2 (for RHEL 7 Server) (RPMs)                        |      |     |         | rhel-7-server-satellite-6.2-rpms         | default
#4831 | Red Hat Satellite Tools 6.2 (for RHEL 7 Server) (RPMs)                  |      |     |         | rhel-7-server-satellite-tools-6.2-rpms   | default
#2463 | Red Hat Enterprise Linux 7 Server - Optional (RPMs)                     |      |     |         | rhel-7-server-optional-rpms              | default
#2455 | Red Hat Enterprise Linux 7 Server (Kickstart)                           |      |     |         | rhel-7-server-kickstart                  | default
#3030 | Red Hat Enterprise Linux 7 Server - Extras (RPMs)                       |      |     |         | rhel-7-server-extras-rpms                | default
#2456 | Red Hat Enterprise Linux 7 Server (RPMs)                                |      |     |         | rhel-7-server-rpms                       | default
#-----|-------------------------------------------------------------------------|------|-----|---------|------------------------------------------|---------

