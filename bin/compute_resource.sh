#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg

#exec >> ../log/compute_resource.log 2>&1

hammer compute-resource create --description 'LibVirt Compute Resource' --locations 'Default Location' --name Libvirt_CR --organizations "$ORG" --url 'qemu+tcp://192.168.126.1/system/' --provider libvirt --set-console-password 0
