#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
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
export HOME=/root


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

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "virt" ]];then
 echo ""
 echo "Need to run this on the 'virt' node"
 echo ""
 exit 1
fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

#https://developers.redhat.com/products/cdk/hello-world/#fndtn-rhel
cd /etc/pki/rpm-gpg
wget -O RPM-GPG-KEY-redhat-devel https://www.redhat.com/security/data/a5787476.txt
rpm --import RPM-GPG-KEY-redhat-devel

yum -y install cdk-minishift docker-machine-kvm

minishift setup-cdk

export MINISHIFT_USERNAME=rhn-gps-apraythe
echo export MINISHIFT_USERNAME=$MINISHIFT_USERNAME >> ~/.bashrc

minishift start

minishift console
minishift console --url

#After the minishift VM has been started, you need to add oc to your PATH. The oc command must match the version of the OpenShift cluster that is running inside of the Red Hat VM. The following command sets the correct version dynamically by running minishift oc-env and parsing the output.
eval $(minishift oc-env)

#Stopping minishift and the CDK life-cycle
#You can stop the minishift VM with the command:

#minishift stop
#You can restart it again with:

#minishift start
#If necessary, you can delete the VM to start over with a clean VM using:

#minishift delete
#You won't need to run minishift setup-cdk again unless you delete the contents of ~/.minishift. You can learn more in the CDK life-cycle section of the CDK Getting Started Guide.


