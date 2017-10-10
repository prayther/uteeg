#!/bin/bash

# virt-inst.sh uses a libvirt host as a Kickstart server, NFS host, Satellite/RHEL DVD repository and local CDN.
# It utilizes local media, RHEL & Satellite DVD media to install satellite. If available it also connects to
# Red Hat CDN with a valid account and pool id.
# Setup:
# cd /var/www/html && git clone https://github.com/prayther/uteeg.git
# ln -s uteeg ks
# cp ~/Downloads/rhel-server-7.3-x86_64-dvd.iso /var/www/html/ks/iso/
# cp ~/Downloads/satellite-6.2.10-rhel-7-x86_64-dvd.iso /var/www/html/ks/iso/
# cp ~/Downloads/manifest.zip /var/www/html/ks/manifest/
# ./virt-inst.sh testvm 10 2 2048

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

# bsfl are bash libs used in scripts in uteeg
ls -d ~/bsfl || git clone https://github.com/SkypLabs/bsfl.git /root/bsfl

# read configuration (needs to be adopted!)
#source etc/virt-inst.cfg
source etc/virthost.cfg
source etc/rhel.cfg
source ./bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

#if [ -z "${1}" ]; [ -z "${2}" ]; [ -z "${3}" ]; [ -z "${4}" ];then
if [ -z "${1}" ];then
  echo ""
  echo " ./virt-install.sh <vmname> <disc in GB> <vcpus> <ram>"
  echo ""
  echo "Ex: ./virt-install.sh testvm 10 2 2048"
  echo ""
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

# Install httpd for ks, iso, manifest.zip
for sw in git ansible virt-manager virt-install virt-viewer nfs-utils httpd;
  do cmd "rpm -q "${sw}"" || dnf install "${sw}"
done
cmd systemctl is-enabled httpd \
	|| cmd systemctl enable httpd \
	|| die_if_false msg_failed "Line $LINENO: could not enable httpd"
cmd systemctl is-active httpd \
	|| cmd systemctl start httpd \
	|| die_if_false msg_failed "Line $LINENO: could not start httpd"
cmd firewall-cmd --info-service http \
	|| firewall-cmd --permanent --add-service=http && firewall-cmd --reload \
	|| die_if_false msg_failed "Line $LINENO: could not setup firewall-cmd httpd" 

#this set vars per vm from hosts file based on $1, vmname used to launch this script
inputfile=etc/hosts
VMNAME=$(awk /"${1}"/'{print $1}' "${inputfile}")
DISC_SIZE=$(awk /"${1}"/'{print $2}' "${inputfile}")
VCPUS=$(awk /"${1}"/'{print $3}' "${inputfile}")
RAM=$(awk /"${1}"/'{print $4}' "${inputfile}")
IP=$(awk /"${1}"/'{print $5}' "${inputfile}")
OS=$(awk /"${1}"/'{print $6}' "${inputfile}")
RHVER=$(awk /"${1}"/'{print $7}' "${inputfile}")
OSVARIANT=$(awk /"${1}"/'{print $8}' "${inputfile}")
VIRTHOST=$(awk /"${1}"/'{print $9}' "${inputfile}")
DOMAIN=$(awk /"${1}"/'{print $10}' "${inputfile}")
DISC=$(awk /"${1}"/'{print $11}' "${inputfile}")
NIC=$(awk /"${1}"/'{print $12}' "${inputfile}")
MASK=$(awk /"${1}"/'{print $13}' "${inputfile}")
ISO=$(awk /"${1}"/'{print $14}' "${inputfile}")
MEDIA=$(awk /"${1}"/'{print $15}' "${inputfile}")
NETWORK=$(awk /"${1}"/'{print $16}' "${inputfile}")

cmd has_value VMNAME
cmd has_value DISC_SIZE
cmd has_value VCPU
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

#sets a uniq name for the ks file
UNIQ=${VMNAME}_$(date '+%s')

#test that the vm config files exist
cmd file_exists ks/network/${VMNAME}.network \
	|| die_if_false msg_failed "Line $LINENO: ./ks/network/"${VMNAME}".network does not exist"
cmd file_exists "ks/partitions/"${VMNAME}".partitions" \
	|| die_if_false msg_failed "Line $LINENO: ./ks/partitions/"${VMNAME}".partitions does not exist"
cmd file_exists "./ks/packages/"${VMNAME}".packages" \
	|| die_if_false msg_failed "Line $LINENO: ./ks/packages/"${VMNAME}".packages does not exist"
cmd file_exists "./ks/post/"${VMNAME}".post" \
	|| die_if_false msg_failed "Line $LINENO: ./ks/post/"${VMNAME}".post does not exist"

#move to function file somewhere
#setup the 10.0.0.0 libvirt network no dhcp and default it on
libvirt_create_laptoplab_network() {
  echo "Line $LINENO: creating libvirt network: /etc/libvirt/qemu/networks/laptoplab.xml"
  echo
  echo "restarting libvirtd..."
  cat << "EOFLAPTOPLAB" > /etc/libvirt/qemu/networks/laptoplab.xml
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh net-edit laptoplab
or other application using the libvirt API.
-->

<network>
  <name>laptoplab</name>
  <uuid>dca25628-b900-42a6-8176-14b660005520</uuid>
  <forward dev='wlp4s0' mode='nat'>
    <interface dev='wlp4s0'/>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:ab:29:e0'/>
  <domain name='laptoplab'/>
  <ip address='10.0.0.1' netmask='255.255.255.0'>
  </ip>
</network>
  virsh net-autostart laptoplab
  systemctl restart libvirtd
EOFLAPTOPLAB
}
cmd file_exists "/etc/libvirt/qemu/networks/laptoplab.xml" \
	|| libvirt_create_laptoplab_network

cmd directory_exists /var/www/html/uteeg \
	|| die_if_false msg_failed "Line $LINENO: execute: cd /var/www/html && git clone https://github.com/prayther/uteeg && cd uteeg && git clone https://github.com/skyplabs/bsfl"
cmd ls -l /var/www/html/ks \
	|| cmd ln -s /var/www/html/uteeg /var/www/html/ks \
	|| die_if_false msg_failed "Line $LINENO: unable to create ln -s uteeg ks"

#setup rhel server kickstart media in /var/www/html/uteeg/rhel
# assume media is located at $RHEL_ISO, etc/rhel.cfg
cmd directory_exists /mnt/rhel \
	|| cmd mkdir -pv /mnt/rhel \
	|| die_if_false msg_failed "Line $LINENO: could not mkdir /mnt/rhel"
cmd mount -o loop /tmp/"${RHEL_ISO}" /mnt/rhel \
	|| die_if_false msg_failed "Line $LINENO: put "${RHEL_ISO}" in /tmp and I'll mount and copy it for ks and move it to url://../iso"
cmd directory_exists /var/www/html/uteeg/rhel \
	|| cmd mkdir -v /var/www/html/uteeg/rhel \
	|| die_if_false msg_failed "Line $LINENO: could not mkdir /var/www/html/uteeg/rhel"
cmd directory_exists /var/www/html/uteeg/rhel/Packages \
	|| cmd rsync -av /mnt/rhel/* /var/www/html/uteeg/rhel/ \
	|| die_if_false msg_failed "Line $LINENO: could not rysnc /mnt/rhel/"
cmd umount /mnt/rhel
cmd directory_exists /var/www/html/uteeg/iso \
        || cmd mkdir -pv /var/www/html/uteeg/iso \
        || die_if_false msg_failed "Line $LINENO: could not mkdir /uteeg/iso"
cmd file_exists /var/www/html/uteeg/iso/"${ISO}" \
        || cmd mv /tmp/"${ISO}" /var/www/html/uteeg/iso/"${ISO}" \
        || die_if_false msg_failed "Line $LINENO: could not mv rhel dvd from tmp to uteeg/iso"
cmd directory_exists rhel/Packages/repodata \
	|| cmd createrepo_c rhel/Packages \
	|| die_if_false msg_failed "Line $LINENO: Need RHEL media setup /var/www/html/uteeg/rhel/Packages/repodata"

# this will be the uniq ks.cfg file for building this vm
cat >> ./ks_${UNIQ}.cfg <<EOF
# System authorization information
reboot
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
#cdrom
#if [[ ${OS} == "fedora" ]];then
#  url --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
#fi

url --url "${URL}/${MEDIA}"
#this repo is just rhel dvd. which makes it, special evidently. had to cd Packages: create_repo and point to that.
#this messes up the versions of packages and breaks gluster, thus the entire kickstart. kickstart console Ctrl-Alt 2 less G /tmp/packages
#repo --name=rhelbase --baseurl=http://"${VIRTHOST}"/ks/rhel/Packages/
# Use graphical install
#text
cmdline
# Run the Setup Agent on first boot
firstboot --disable
ignoredisk --only-use=$DISC
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
%include /tmp/${VMNAME}.network

# Root password
rootpw --iscrypted \$6\$zBfR6/MikcoIX79Q\$G5Dv5HxUmsRrEOy2kTtrgO3o0rx7zNyvJWFhZpubxX9hhlH1bM7n9HW/6y6coDwsrO8qZssMRyxpdbSeSJoMO.
# System timezone
timezone America/New_York --isUtc
# System bootloader configuration
bootloader --location=mbr --boot-drive=$DISC

# Partition clearing information
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
%include /tmp/${VMNAME}.partitions

#repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64
#repo --name=rhel --baseurl=http://"${VIRTHOST}"/ks/rhel

%packages
#@core
%include /tmp/${VMNAME}.packages
%end

%pre
#!/bin/bash
hostname=""
set -- `cat /proc/cmdline`
for I in $*; do case "$I" in *=*) eval $I;; esac; done

curl ${URL}/ks/network/${VMNAME}.network > /tmp/${VMNAME}.network
curl ${URL}/ks/post/${VMNAME}.post > /tmp/${VMNAME}.post
curl ${URL}/ks/partitions/${VMNAME}.partitions > /tmp/${VMNAME}.partitions
curl ${URL}/ks/packages/${VMNAME}.packages > /tmp/${VMNAME}.packages
%end

%include /tmp/${VMNAME}.post

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end

%post
# Backup the original rc.local file... empty
cp /etc/rc.local /root/rc.local.orig

# step one creat a file to run by rc.local at next boot
cat << "EOFKS" > /tmp/ks_virt-inst.sh
#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> /root/ks_virt-inst.log; done; }
exec 2> >(LOG_)

#jump through hoops to get git (not on the gluster dvd) so that we can pull down the git repo to config with
yum-config-manager --add-repo http://"${VIRTHOST}"/ks/rhel/Packages
rpm --import http://"${VIRTHOST}"/ks/rhel/RPM-GPG-KEY-redhat-release
yum -y install git
rm -f /etc/yum.repos.d/"${VIRTHOST}"*.repo

cd /root && /usr/bin/git clone https://github.com/prayther/uteeg.git
cd /usr/local && /usr/bin/git clone https://github.com/prayther/uteeg.git
$ it gets extraneous stuff in there from my laptop.
> /root/uteeg/log/virt-inst.log

mkdir /root/.ssh
chmod 700 /root/.ssh

# Use different keys
cat << "ROOTSSHKEY" > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD6bwWbzdzwx33QMR5FwUosXraOchkS5Ci7wj5s1taW62vzrlxXQF1RzxAegCTaJKy4sKcoMgNmx77TsXkaqA/vfzkgW//EStMr/q/QGzMePS/uYaUyGf0XvmUnouEKgUQhRq8q0G4Wa9uOmsiQDJEgIexyXZa8HSRo2dWyJd4A0UcJklR4yvTMuNd8Uq1qAVuMzBhy1075DMNRi56RW5bRs2N2nhiFuesC6RF3RDJKkRO6ld3e+0ddqFWhMIYyB9VpifH6UnSBUUmu3yW8uqFJ3Pnh908lWYqqADNj5zBezTi+mJqdKhZF77RaDhaBLG1i+llf0NBqHBWiihoeKbFP root@fedora-26.prayther.org
ROOTSSHKEY
chmod 400 /root/.ssh/authorized_keys

cat << "ID_RSA" > /root/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA+m8Fm83c8Md90DEeRcFKLF62jnIZEuQou8I+bNbWlutr865c
V0BdUc8QHoAk2iSsuLCnKDIDZse+07F5GqgP7385IFv/xErTK/6v0BszHj0v7mGl
Mhn9F75lJ6LhCoFEIUavKtBuFmvbjprIkAyRICHscl2WvB0kaNnVsiXeANFHCZJU
eMr0zLjXfFKtagFbjMwYctdO+QzDUYuekVuW0bNjdp4YhbnrAukRd0QySpETupXd
3vtHXahVoTCGMgfVaYnx+lJ0gVFJrt8lvLqhSdz54fdPJVmKqgAzY+cwXs04vpia
nSoWRe+0Wg4WgSxtYvpZX9DQahwVoooaHimxTwIDAQABAoIBAQCIaUUS0xXQCboc
V0T4FgtDE+w4tym1QpZ1f57lRjjpSB8rQwSFekfasgFDu+VW9bcnewHyQRvdNlxZ
j0g6HuVfPVtupu4wi9lvE3HM16QGiqm7HXEQU1urPUh4SJ5wTG1B+vCbT6FHkUSs
7t7kqBO8/v1+ZkAfA3i7rDxcp4e/xSslnYCXVH5D0bi9+MG9UxQIFAuwQgcycq5U
V7Zdjqrq3Ky7kdLovYxR5z6NFc02w07xRWLl4wPKFYk2iOk1eOpNAQUIPZJy5MLj
/+oGMaSpVNV1tpU/7Exo43ZZuZW3tqFDHaNZXArezGhQ8QnHHB4FUvm5kLWVRh8m
+nGAQulRAoGBAP7c6rOiTswAJ2HT7nEN80CvBqtw6l8oFkjJ0L8R9bw/YFE779JB
Nhutncw7BdfwNmPjhWnKKiQOZeR+fVOeg8g40UN/ZibxrU2cPnrkASijAovLvGsi
HpyEvgjeRgfotHTanpnME0wGQwZwQ2Pyc2lOZ1BppbVAOaiRh4TwSQpVAoGBAPuN
C93nA6CoT3OCM3HMn7NgZwoKtIgPFMsOZEvgB85tRCwWSiypgwNxjUzc+lamBZDm
KiPEr5B6JgjOseFAVAUdtUSNLUFhhUdhRr1N/dJbfJ/HofMC46OgpfPeT1Z91tcC
znwOF5sc9NfP/oMN0A5pN4Wm2dyaAJItUz3irTkTAoGBALwhZRrOz+2km22KXLOV
gZ+Y04qQImG1nKWEXBP+9O9NtRKh9Mi2nHNX+Gh+lTSuO+gGVkAeHHdbLXm6qVal
Z0/QKSDzFPvgYHYuxKxATF6r3cBF10MZ/5C4J/Mx6G4EJ9kuW+7ZhtESuj0xd316
xhjQ6FCie9DMpQM60dee67u1AoGAX6xvnQBmMs6RGV+l7VxkSTcbOYiEzVLfF7Pr
lagpj+ujCBmaMI5wU/j2Qwuw8w/GAixoTp5aH9s1aBglM4Th7+gyr1X6pmlO5a0r
2Ig3R7CgH60v/VtV9T/+nlgpWL4X3kMlAa3icI582TA0nue8AB8ojN6+8dZo7S/r
/xedxp0CgYEAgV0xPARPljKUL7cpL/t7FZb57evsZNAd98aouDnp439b0Pa0KHkZ
7RcOeP6DRkvMJ9g3Wnm7St5EDPxyEPRCGDshAYAFSaeF4Orons/Iz4724eEZIDIq
dHwtQJG7tETeacgIRw9LwNKhTV9UOSDc72o5tJGXtaPugQuJ4sRLS6A=
-----END RSA PRIVATE KEY-----
ID_RSA
chmod 600 /root/.ssh/id_rsa

cat << "ID_RSAPUB" > /root/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD6bwWbzdzwx33QMR5FwUosXraOchkS5Ci7wj5s1taW62vzrlxXQF1RzxAegCTaJKy4sKcoMgNmx77TsXkaqA/vfzkgW//EStMr/q/QGzMePS/uYaUyGf0XvmUnouEKgUQhRq8q0G4Wa9uOmsiQDJEgIexyXZa8HSRo2dWyJd4A0UcJklR4yvTMuNd8Uq1qAVuMzBhy1075DMNRi56RW5bRs2N2nhiFuesC6RF3RDJKkRO6ld3e+0ddqFWhMIYyB9VpifH6UnSBUUmu3yW8uqFJ3Pnh908lWYqqADNj5zBezTi+mJqdKhZF77RaDhaBLG1i+llf0NBqHBWiihoeKbFP root@fedora-26.prayther.org
ID_RSAPUB
chmod 644 /root/.ssh/id_rsa.pub

# setup known_hosts in both directions for libvirt host and vm
# VIRTHOST is the libvirt host. hostname will be the vm in question because hostname evaluates before sending the command
ssh -o StrictHostKeyChecking=no root@${VIRTHOST} "ssh -o StrictHostKeyChecking=no root@${VMNAME}.${DOMAIN} exit"

cat << "EOFKS1" > /tmp/ks_virt-inst1.sh
#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> /root/ks_virt-inst.log; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# run all the install/cfg scripts in sequence. the names determine order.
#/root/uteeg/bin/run_all.sh

# step 2 put the orig rc.local in place and reboot
cp /root/rc.local.orig /etc/rc.local
EOFKS1

chmod 0755 /etc/rc.local

cat << "EOH1" > /etc/rc.d/rc.local
#!/bin/bash

bash /tmp/ks_virt-inst1.sh
EOH1
chmod 0755 /etc/rc.local

# adding logic to the register scripts themselves
# register script comes from uteeg git project cloned above
/bin/bash ~/uteeg/bin/00500_register_update.sh

# step 2 put the orig rc.local in place
#cp /root/rc.local.orig /etc/rc.local
reboot
EOFKS

cat << "EOH" > /etc/rc.d/rc.local
#!/bin/bash

bash /tmp/ks_virt-inst.sh
EOH
chmod 0755 /etc/rc.local
%end

EOF
#this is very much setup for testing over and over... the same vm.
#so be very careful with the next few commands that destroy anything existing without confirmation.

#configure ansible
cmd rpm -q ansible || /usr/bin/yum install -y ansible
cmd grep -i "${VMNAME}.${DOMAIN}" /etc/ansible/hosts \
	|| cmd echo ["${VMNAME}"] >> /etc/ansible/hosts
cmd grep -i "${VMNAME}.${DOMAIN}" /etc/ansible/hosts \
	|| cmd echo "${VMNAME}.${DOMAIN}" >> /etc/ansible/hosts
#unregister so you don't make a mess on cdn
cmd ansible "${VMNAME}.${DOMAIN}" --timeout=5 -a "/usr/sbin/subscription-manager unregister" \
	|| msg_warning "OK if ansible unregister CDN fails."

virsh list --all | grep "${VMNAME}" && cmd virsh destroy "${VMNAME}"
virsh list --all | grep "${VMNAME}" && cmd virsh undefine "${VMNAME}"
cmd rm -f /var/lib/libvirt/images/"${VMNAME}".qcow2
cmd rm -f /var/lib/libvirt/images/"${VMNAME}".data.qcow2

#if the ip does not exist make a hosts entry into libvirt (dnsmasq) host so that the vm will resolve. important for satellite
cmd 'grep -i "${IP} ${VMNAME}.${DOMAIN} ${VMNAME}" /etc/hosts' || echo "${IP} ${VMNAME}.${DOMAIN} ${VMNAME}" >> /etc/hosts

#virsh net-destroy ${NETWORK}
#virsh net-start ${NETWORK}

cmd file_exists ~/.ssh/id_rsa \
	 || ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa \
	 || die_if_false msg_failed "Line $LINENO: could not ssh-keygen" 

# just remove so ssh won't fail. ks/boot scripts put it back for a new vm later
msg_ok grep ${VMNAME} /root/.ssh/known_hosts \
	&& cmd sed -i /${VMNAME}/d /root/.ssh/known_hosts
msg_ok grep ${VMNAME} /root/.ssh/known_hosts \
        && cmd sed -i /${VMNAME}/d /home/"${VIRTHOSTUSER}"/.ssh/known_hosts
msg_ok grep ${IP} /root/.ssh/known_hosts \
        && cmd sed -i /${IP}/d /root/.ssh/known_hosts
msg_ok grep ${IP} /root/.ssh/known_hosts \
        && cmd sed -i /${IP}/d /home/"${VIRTHOSTUSER}"/.ssh/known_hosts

#list of os-variant: osinfo-query os
#making an exception for virt 'name' and not os variant. doing host cpu passthru
#if [[ $(echo ${VMNAME} | grep virt) ]];then
#virt-install \
#   --name="${VMNAME}" \
#   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
#   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=50,sparse=false,format=qcow2,cache=none \
#   --ram="${RAM}" \
#   --cpu host-passthrough \
#   --location=/var/lib/libvirt/images/"${RHEL_ISO}" \
#   --os-type=linux \
#   --noautoconsole --wait -1 \
#   --os-variant=rhel"${OSVARIANT}" \
#   --network network="${NETWORK}" \
#   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${VIRTHOST}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF} nameserver=${VIRTHOST}"
#fi

#when looking at size, for sparse (thin provision) use du -sh, ls will show you what the OS thinks.
#you can set sparse=false but performance is terrible
#i setup a second disc sparse just in case. if you find you really need it probably make it sparse=false
#virt_install() {
virt-install \
   --name="${VMNAME}" \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",cache=writeback,sparse=false,format=qcow2,cache=none \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=50,cache=writeback,sparse=false,format=qcow2,cache=none \
   --vcpus="${VCPUS}" --ram="${RAM}" \
   --location=/var/lib/libvirt/images/"${ISO}" \
   --os-type=linux \
   --noautoconsole --wait -1 \
   --os-variant=rhel"${OSVARIANT}" \
   --network network="${NETWORK}" \
   --extra-args "ks=${URL}/ks_${UNIQ}.cfg ip=${IP} gateway=${VIRTHOST} netmask=${MASK} hostname=${VMNAME}.${DOMAIN} device=${NIC} nameserver=${VIRTHOST}"
#   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${VIRTHOST}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF}"
#   --extra-args "ks=${URL}/ks_${UNIQ}.cfg ip=${IP} gateway=${VIRTHOST} netmask=${MASK} hostname=${VMNAME}.${DOMAIN} device=${NIC} nameserver=${VIRTHOST}"
   #--extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${VIRTHOST}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF} nameserver=${VIRTHOST}"
#   --extra-args "ks=${URL}/ks_${UNIQ}.cfg ip=${IP} gateway=${VIRTHOST} netmask=${MASK} hostname=${VMNAME}.${DOMAIN} device=${NIC} nameserver=${VIRTHOST}"
#}
#cmd virt-install || die_if_false msg_failed "Line $LINENO: Actual VM creation with Libvirt failed"

#[root@localhost disk]# virt-install --name=server2.example.com --ram=2048 --vcpus=2 --autostart --os-type=linux --extra-args='ks=ftp://192.168.0.43/pub/centos/ks.cfg ksdevice=ens3 ip=192.168.122.90 netmask=255.255.255.0 gateway=192.168.122.1 dns=8.8.8.8' --disk vol=skladishte/volume1,bus=virtio --location=ftp://192.168.0.43/pub/centos --network bridge=virbr0

#if [[ "${OS}" = "rhgf" ]];then
#virt-install \
#   --name="${VMNAME}" \
#   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
#   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=150,sparse=false,format=qcow2,cache=none \
#   --vcpus="${VCPUS}" --ram="${RAM}" \
#   --location=/var/lib/libvirt/images/"${RHGS_ISO}" \
#   --os-type=linux \
#   --noautoconsole --wait -1 \
#   --os-variant=rhel"${OSVARIANT}" \
#   --network network="${NETWORK}" \
#   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${VIRTHOST}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF} nameserver=${VIRTHOST}"
#fi
#if [[ "${OS}" = "fedora" ]];then
#virt-install \
#   --name="${VMNAME}" \
#   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
#   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=150,sparse=false,format=qcow2,cache=none \
#   --vcpus="${VCPUS}" --ram="${RAM}" \
#   --location=/var/lib/libvirt/images/"${FEDORA_ISO}" \
#   --os-type=linux \
#   --noautoconsole --wait -1 \
#   --os-variant=generic
#   --network network="${NETWORK}" \
#   --initrd-inject=vm.ks --extra-args "ks=file:/var/www/html/ks/ks_${UNIQ}.cfg" \
#   --extra-args "ip=${IP}::${VIRTHOST}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF} nameserver=${VIRTHOST}"
#fi

