#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg

#hammer --cvs location list | awk -F"," '{print $2}'
#exec >> ../log/compute_resource.log 2>&1

hammer compute-resource create --description 'LibVirt Compute Resource' --locations ${LOC} --name Libvirt_CR --organizations "$ORG" --url "qemu+ssh://root@${GATEWAY}/system/" --provider libvirt --set-console-password 0

firewall-cmd --add-port=5910-5930/tcp
firewall-cmd --add-port=5910-5930/tcp --permanent

# setup for compute resource with libvirt
#su - foreman -s /bin/bash
#ssh-keygen
#ssh-copy-id root@${GATEWAY}

# import crt for libvirt vm console on your workstation/laptop browser
#http://10.0.0.8/pub/katello-server-ca.crt
