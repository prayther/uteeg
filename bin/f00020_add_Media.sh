#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg
#source ../etc/enable_rhel.cfg
#source ../etc/install-configure-satellite.cfg

#exec >> ../log/media.log 2>&1
exec >> ../log/virt_inst.log 2>&1

# Operating Systems are automatically added as the kickstart repos are synchronised.
# Associate the operating systems hosted on this server with the specified organisation and location.
# this is only acting on one Location and Organization.
for i in $(hammer --csv medium list | grep $(hostname) | cut -d, -f1)
do
   hammer organization add-medium --name ${ORG} --medium-id ${i}
   hammer location add-medium --name ${LOC} --medium-id ${i}
done

