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

# This seems to work as a 'safety net' and upgrades after installing from media
katello-service stop
satellite-installer --scenario satellite --upgrade

# Notice adding of tftp for provisioning from capsules and the removal of Puppet
#katello-service status || satellite-installer --scenario satellite \
#satellite-installer --scenario satellite \
#--foreman-initial-organization "${ORG}" \
#--foreman-initial-location "${LOC}" \
#--foreman-admin-username admin \
#--foreman-admin-password password \
#--foreman-proxy-tftp true \
#--foreman-proxy-tftp-servername $(hostname)  #--foreman-proxy-puppetca true \ # sat62=--capsule-puppet true

#update for sat64
satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-initial-location "${LOC}" \
--foreman-admin-username admin \
--foreman-admin-password password \
--foreman-proxy-puppetca true \
--foreman-proxy-tftp true \
--enable-foreman-plugin-discovery

#Upload our manifest.zip (created in RH Portal)
wget -P /root/ --no-clobber http://${SERVER}/ks/manifest/manifest.zip
hammer subscription upload --file /root/manifest.zip  --organization=${ORG}
hammer subscription refresh-manifest --organization=${ORG}

# Configuring Basic Authentication for Red Hat Access Insights in Satellite 6.1.1
# Edit /etc/redhat_access/config.yml and change 'enable_telemetry_basic_auth' from false (default) to true. Example:
# In the UI, navigate to Access Insights -> Manage. You'll now see an option under Access Insights Service Configuration to input a username/password.

# timeout for testing.
hammer settings set --name idle_timeout --value 99999999

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
