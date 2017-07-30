#!/bin/bash -x

# this script broke at last fedora 26 update of qemu* packages
# did some trouble shooting, removing all but the 'hammer host create'
# and then adding the cdrom manually and it still just flickers on the boot screen
# created a vm manually in virt-manager and set the mac on the host for satellite and that worked
# it made me think it was how satellite is interacting with libvirt compute resource
# hope this will just start magically working again.
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

doit vmname="test02"
doit vmip="10.0.0.11"

doit hammer host create \
--name="${vmname}" \
--hostgroup=HG_Infra_1_Dev_CCV_RHEL7_Server_ORG_redhat_LOC_laptop \
--organization=redhat \
--location=laptop \
--interface="primary=true,compute_type=network,compute_network=laptoplab,ip=${vmip}" \
--subnet="10.0.0.0/24" \
--volume="capacity=10G,format_type=qcow2" \
--compute-attributes="memory=1024" \
--compute-resource=Libvirt_CR

# bootdisk host pulls down the boot media from satellite
doit hammer bootdisk host --host=${vmname}.${DOMAIN}
doit scp ${vmname}.${DOMAIN}.iso ${GATEWAY}:/var/lib/libvirt/images/
# this is how to inline edit a libvirt vm to add cdrom
doit ssh ${GATEWAY} "virsh dumpxml ${vmname}.${DOMAIN} > /tmp/${vmname}.${DOMAIN}.xml"
doit ssh ${GATEWAY} "sed -i '/dev=\'network\'/a \ \ \ \ <boot dev=\'cdrom\'\ \/>' /tmp/${vmname}.${DOMAIN}.xml"
# search for </disk> and insert
doit cat << EOH > /root/cdrom.txt
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hda' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
EOH
doit scp /root/cdrom.txt ${GATEWAY}:/var/lib/libvirt/images/
doit ssh ${GATEWAY} "sed -iE '/\/disk\>/r /var/lib/libvirt/images/cdrom.txt' /tmp/${vmname}.${DOMAIN}.xml"
doit ssh ${GATEWAY} "/bin/virsh define /tmp/${vmname}.${DOMAIN}.xml"
doit ssh ${GATEWAY} "/bin/virsh start ${vmname}.${DOMAIN}"
doit ssh ${GATEWAY} "/bin/virsh attach-disk ${vmname}.${DOMAIN} /var/lib/libvirt/images/${vmname}.${DOMAIN}.iso hda --type cdrom --mode readonly"
doit ssh ${GATEWAY} "/bin/virsh reset ${vmname}.${DOMAIN}"








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

