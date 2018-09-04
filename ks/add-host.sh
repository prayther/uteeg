#!/bin/bash -x

#Usage: ./script.sh hostname

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

# bsfl are bash libs used in scripts in uteeg
ls -d ~/bsfl || git clone https://github.com/SkypLabs/bsfl.git /root/bsfl

# read configuration (needs to be adopted!)
#source etc/virt-inst.cfg
source ../etc/virthost.cfg
source ../etc/rhel.cfg
source ../bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

#if [ -z "${1}" ]; [ -z "${2}" ]; [ -z "${3}" ]; [ -z "${4}" ];then
if [ -z "${1}" ];then
  echo ""
  #echo " ./virt-install.sh <vmname> <disc in GB> <vcpus> <ram>"
  echo " ./virt-install.sh <vmname>
  echo ""
  echo "Ex: ./virt-install.sh testvm
  #echo "Ex: ./virt-install.sh testvm 10 2 2048"
  echo ""
  echo "Make sure you have an entry in uteeg/etc/hosts for your vmname"
  echo "Only run one of these at a time. Building multiple"
  echo "VM's gets all wacky with the libvirtd restart and "
  echo "starting and stopping the network"
  echo ""
  echo "All the starting and stopping is to get dhcp leases straight"
  echo ""
  echo ""
  exit 1
fi

# make sure your your libvirt host has sw needed for virt-inst.sh
#for sw in ansible virt-manager virt-install virt-viewer nfs-utils httpd;
#  do
#    if [[ $(rpm -q "${sw}") ]];then
#      echo ""${sw}" installed"
#    else
#      echo ""${sw}" not installed..."
#      echo "yum install -y "${sw}" # run this and try again"
#      exit 1
#    fi
#done


#this set vars per vm from hosts file based on $1, vmname used to launch this script
#use ^ in search to make sure you're not getting comments #
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

cmd has_value VMNAME
cmd has_value DISC_SIZE
cmd has_value VCPUS
cmd has_value RAM
cmd has_value IP
cmd has_value OS
cmd has_value RHVER
cmd has_value OSVARIANT
cmd has_value VIRTHOST
cmd has_value DISC
cmd has_value NIC
cmd has_value MASK
cmd has_value ISO
cmd has_value MEDIA
cmd has_value NETWORK


cp packages/template.packages packages/${VMNAME}.packages
cp partitions/template.partitions partitions/${VMNAME}.partitions
cp post/template.post post/${VMNAME}.post
cp network/template.network network/${VMNAME}.network
# sed search replace &: refer to that portion of the pattern space which matched
sed -i "s/<IP>/${IP}/g" network/${VMNAME}.network
sed -i "s/<VMNAME>/${VMNAME}/g" network/${VMNAME}.network
sed -i "s/<DOMAIN>/${DOMAIN}/g" network/${VMNAME}.network

