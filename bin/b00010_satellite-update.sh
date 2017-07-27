#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# This seems to work as a 'safety net' and upgrades after installing from media
satellite-installer --scenario satellite --upgrade

# Notice adding of tftp for provisioning from capsules and the removal of Puppet
/usr/sbin/satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-initial-location "${LOC}" \
--foreman-admin-username admin \
--foreman-admin-password password \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-servername $(hostname) \
--capsule-puppet false

#Upload our manifest.zip (created in RH Portal)
cd /root && wget --no-clobber http://${SERVER}/ks/manifest/manifest.zip
hammer subscription upload --file /root/manifest.zip  --organization=${ORG}

# timeout for testing.
hammer settings set --name idle_timeout --value 99999999
