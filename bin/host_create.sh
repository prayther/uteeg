#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg
source ../etc/ak_create.cfg

#exec >> ../log/host_create.log 2>&1

#hammer compute-resource list
#hammer bootdisk host --host test01.laptop.prayther

#--provision-method build \
#--interface="primary=true, \
#            provision=true, \
#            ip=${vmip}" \
#--domain laptop.prayther \
#--compute-attributes="start=true" \
#--subnet "10.0.0.0/24" \
#--compute-profile="1-Small" \
#--ask-root-password no
#--compute-profile-id="1"
#--volume="capacity=10G,format_type=qcow2"
#--compute-attributes="start=1,image_id=/var/lib/libvirt/images/test01.laptop.prayther.iso" \
#--interface="compute_type=network,compute_network=laptoplab,compute_model=virtio" \

vmname="test01"
vmip="10.0.0.10"

hammer host create \
--name "${vmname}" \
--hostgroup HG_Infra_1_Dev_CCV_RHEL7_Server_ORG_redhat_LOC_laptop \
--organization redhat \
--location laptop \
--interface="primary=true,compute_type=network,compute_network=laptoplab,ip=${vmip}" \
--subnet "10.0.0.0/24" \
--volume="capacity=10G,format_type=qcow2" \
--compute-resource Libvirt_CR

hammer bootdisk host --host "${vmname}"
scp "${vmname}" "${GATEWAY}":/var/lib/libvirt/images/
ssh ${GATEWAY} "sed -i 's/dev=\'network\'/dev=\'cdrom\'/g' /etc/libvirt/qemu/${vmname}.xml"
ssh ${GATEWAY} "/bin/virsh start ${vmname}"
ssh ${GATEWAY} "/bin/virsh attach-disk ${vmname} /var/lib/libvirt/images/${vmname}.iso hda --type cdrom --mode readonly"

#[root@sat uteeg]# hammer bootdisk host --host test01.laptop.prayther
# xmlstarlet ??? edit xml from cli
#root@fedora /v/w/h/u/etc# virsh edit test01.laptop.prayther
#  <os>
#    <type arch='x86_64' machine='pc-i440fx-2.9'>hvm</type>
#    <boot dev='cdrom'/>
#    <boot dev='network'/>
#    <boot dev='hd'/>
#  </os>

#Successfully downloaded host disk image to test01.laptop.prayther.iso
#[root@sat uteeg]# scp test01.laptop.prayther.iso 10.0.0.1:/var/lib/libvirt/images/
#test01.laptop.prayther.iso
#libvirt_host> virsh attach-disk test01.laptop.prayther /var/lib/libvirt/images/test01.laptop.prayther.iso hda --type cdrom --mode readonly
#Disk attached successfully

