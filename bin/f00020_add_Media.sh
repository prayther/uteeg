#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# Operating Systems are automatically added as the kickstart repos are synchronised.
# Associate the operating systems hosted on this server with the specified organisation and location.
# this is only acting on one Location and Organization.
for i in $(hammer --csv medium list | grep $(hostname) | cut -d, -f1)
do
   hammer organization add-medium --name ${ORG} --medium-id ${i}
   hammer location add-medium --name ${LOC} --medium-id ${i}
done

