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

#runs or not based on hostname; ceph-?? gfs-??? sat-???
#if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "gfs" ]];then
# echo ""
# echo "Need to run this on the 'gfs' node"
# echo ""
# exit 1
#fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

katello-service status
if [[ ${?} != "0" ]];then
        echo "Either this is not a Satellite, or you have an error on katello-service status"
        echo
        exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

if [[ -z ${0} ]];then
	echo "Have to have an uteeg/etc/hosts entry"
	echo ""
	echo "And use the vmanme as parameter: ./daily_New_host.sh vmname"
	exit 1
fi

#if [[ -z ${0} ]]; [[ -z ${1} ]];then
#	VMNAME="test02"
#	IP="10.0.0.24"
#else
#	VMNAME="${0}"
#	IP="${1}"
#fi

inputfile=../etc/hosts
VMNAME=$(awk /"^${1}"/'{print $1}' "${inputfile}")
DISC_SIZE=$(awk /"^${1}"/'{print $2}' "${inputfile}")
VCPUS=$(awk /"^${1}"/'{print $3}' "${inputfile}")
RAM=$(awk /"^${1}"/'{print $4}' "${inputfile}")
IP=$(awk /"^${1}"/'{print $5}' "${inputfile}")
OS=$(awk /"^${1}"/'{print $6}' "${inputfile}")
RHVER=$(awk /"^${1}"/'{print $7}' "${inputfile}")
OSVARIANT=$(awk /"^${1}"/'{print $8}' "${inputfile}")
VIRTHOST=$(awk /"^${1}"/'{print $9}' "${inputfile}")
DOMAIN=$(awk /"^${1}"/'{print $10}' "${inputfile}")
DISC=$(awk /"^${1}"/'{print $11}' "${inputfile}")
NIC=$(awk /"^${1}"/'{print $12}' "${inputfile}")
MASK=$(awk /"^${1}"/'{print $13}' "${inputfile}")
ISO=$(awk /"^${1}"/'{print $14}' "${inputfile}")
MEDIA=$(awk /"^${1}"/'{print $15}' "${inputfile}")
NETWORK=$(awk /"^${1}"/'{print $16}' "${inputfile}")
LIFECYCLE=$(awk /"^${1}"/'{print $17}' "${inputfile}")
CONTENTVIEW=$(awk /"^${1}"/'{print $18}' "${inputfile}")

ssh ${GATEWAY} "grep -i ${IP} ${VMNAME}.${DOMAIN} ${VMNAME} /etc/hosts || echo ${IP} ${VMNAME}.${DOMAIN} ${VMNAME} >> /etc/hosts"

ssh ${GATEWAY} "systemctl stop libvirtd"
ssh ${GATEWAY} "systemctl stop dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "pkill libvirtd"
ssh ${GATEWAY} "pkill dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl start libvirtd"
ssh ${GATEWAY} "systemctl start dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl status libvirtd"
ssh ${GATEWAY} "systemctl status dnsmasq"

ssh ${GATEWAY} "virsh list --all | grep ${VMNAME} && virsh destroy ${VMNAME}.${DOMAIN}"
ssh ${GATEWAY} "virsh list --all | grep ${VMNAME} && virsh undefine ${VMNAME}.${DOMAIN}"
ssh ${GATEWAY} "rm -fv /var/lib/libvirt/images/${VMNAME}*"
ssh ${GATEWAY} "rm -fv /tmp/${VMNAME}*"
#ssh ${GATEWAY} "rm -f /var/lib/libvirt/images/"${VMNAME}".data.qcow2"
hammer host delete --name="${VMNAME}.${DOMAIN}"

ssh ${GATEWAY} "systemctl stop libvirtd"
ssh ${GATEWAY} "systemctl stop dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "pkill libvirtd"
ssh ${GATEWAY} "pkill dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl start libvirtd"
ssh ${GATEWAY} "systemctl start dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl status libvirtd"
ssh ${GATEWAY} "systemctl status dnsmasq"

#hammer host create \
#--name="${VMNAME}" \
#--hostgroup=HG_Infra_1_Dev_CV_RHEL7_Core_ORG_redhat_LOC_laptop \
#--organization=redhat \
#--location=laptop \
#--interface="primary=true,compute_type=network,compute_network=laptoplab,ip=${IP}" \
#--subnet="10.0.0.0/24" \
#--volume="capacity=10G,format_type=qcow2" \
#--compute-attributes="cpus=1,memory=1024"
#--compute-resource=Libvirt_CR

hammer host create --name "${VMNAME}" --organization "redhat" \
--location "laptop" --hostgroup "HG_${LIFECYCLE}_${CONTENTVIEW}_ORG_${ORG}_LOC_${LOC}" \
--compute-resource "Libvirt_CR" \
--interface "managed=true,primary=true,provision=true,compute_type=network,compute_network=laptoplab,ip=${IP}" \
--subnet="10.0.0.0/24" \
--compute-attributes="cpus=1,memory=1073741824" \
--volume="pool_name=default,capacity=20G,format_type=qcow2"

# bootdisk host pulls down the boot media from satellite
#hammer bootdisk host --force --host=${VMNAME}.${DOMAIN}
hammer bootdisk host --host=${VMNAME}.${DOMAIN}
scp ${VMNAME}.${DOMAIN}.iso ${GATEWAY}:/var/lib/libvirt/images/
# this is how to inline edit a libvirt vm to add cdrom
ssh ${GATEWAY} "virsh dumpxml ${VMNAME}.${DOMAIN} > /tmp/${VMNAME}.${DOMAIN}.xml"
ssh ${GATEWAY} "sed -i '0,/network/s//cdrom/' /tmp/${VMNAME}.${DOMAIN}.xml"
#ssh ${GATEWAY} sed -i /dev=\'network\'/a \ \ \ \ <boot dev=\'cdrom\'\ \/> /tmp/${VMNAME}.${DOMAIN}.xml
# search for </disk> and insert
cat << EOH > /root/cdrom.txt
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hda' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
EOH
scp /root/cdrom.txt ${GATEWAY}:/var/lib/libvirt/images/
ssh ${GATEWAY} "sed -iE '/\/disk\>/r /var/lib/libvirt/images/cdrom.txt' /tmp/${VMNAME}.${DOMAIN}.xml"
ssh ${GATEWAY} "/bin/virsh define /tmp/${VMNAME}.${DOMAIN}.xml"
ssh ${GATEWAY} "/bin/virsh start ${VMNAME}.${DOMAIN}"
ssh ${GATEWAY} "/bin/virsh attach-disk ${VMNAME}.${DOMAIN} /var/lib/libvirt/images/${VMNAME}.${DOMAIN}.iso hda --type cdrom --mode readonly"
ssh ${GATEWAY} "/bin/virsh reset ${VMNAME}.${DOMAIN}"

#all this silly restarting is messing up virt-who
systemctl restart virt-who

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
