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

# If avail. Satellite would be registered to Red Hat CDN, so unregister from there to self register
#unregister_from_RedHat () {
#                           if [[ $(subscription-manager status) -eq "0" ]];then subscription-manager unregister;fi
#		   }
#unregister_from_RedHat

subscription-manager unregister
subscription-manager clean
CA_CONSUMER_RPM=$(rpm -qa | grep katello-ca-consumer)
rpm -e "${CA_CONSUMER_RPM}"
#rpm -qa | grep katello-ca-consumer || rpm -Uvh /var/www/html/pub/katello-ca-consumer-latest.noarch.rpm
rpm -Uvh /var/www/html/pub/katello-ca-consumer-latest.noarch.rpm
# add a activation key once i get satellite repos in my test bed.
setup_slow_var () {
                   Sat_AK=$(hammer --csv activation-key list --organization redhat | grep Infra | grep -vi Capsule | awk -F"," '/Satellite/ {print $2}')
	   }
setup_slow_var

/usr/sbin/subscription-manager --force --org="${ORG}" register --activationkey="${Sat_AK}"
subscription-manager refresh

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
