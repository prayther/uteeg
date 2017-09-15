#!/bin/bash -x

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

logfile="../log/$(basename $0 .sh).log"
donefile="../log/$(basename $0 .sh).done"
touch $logfile
touch $donefile

exec > >(tee -a "$logfile") 2>&1

echo "###INFO: Starting $0"
echo "###INFO: $(date)"

# read configuration (needs to be adopted!)
#. ./satenv.sh
source etc/virt-inst.cfg


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
for sw in ansible virt-manager virt-install virt-viewer nfs-utils httpd;
  do
    if [[ $(rpm -q "${sw}") ]];then
      echo ""${sw}" installed"
    else
      echo ""${sw}" not installed..."
      echo "yum install -y "${sw}" # run this and try again"
      exit 1
    fi
done

#this set vars per vm from hosts file based on $1, vmname used to launch this script
inputfile=./etc/hosts
VMNAME=$(awk /"${1}"/'{print $1}' "${inputfile}")
DISC_SIZE=$(awk /"${1}"/'{print $2}' "${inputfile}")
VCPU=$(awk /"${1}"/'{print $3}' "${inputfile}")
RAM=$(awk /"${1}"/'{print $4}' "${inputfile}")
IP=$(awk /"${1}"/'{print $5}' "${inputfile}")
OS=$(awk /"${1}"/'{print $6}' "${inputfile}")
RHVER=$(awk /"${1}"/'{print $7}' "${inputfile}")
OSVARIANT=$(awk /"${1}"/'{print $8}' "${inputfile}")
#vmname needs to have the structure:
#sat-*
#ceph-*
#gfs-*
#PRODUCT=$(echo "${VMNAME}" | awk -F"-" '{print $1}')

#Pull vm info from hosts file
#inputfile=./etc/hosts
#while IFS=" " read -r VMNAME DISC_SIZE VCPU RAM IP; do
#  VMNAME="$VMNAME"
#  DISC_SIZE="$DISC_SIZE"
#  VCPU="$VCPU"
##  MEM="$RAM"
#  IP="$IP"
#done < "$inputfile" | grep $1

# This is just saving the info in virt-inst.cfg. You have to use all 4 parameters each time
# You will have a history of the last values for each uniq vmname you have used saved in virt-inst.cfg
#VMNAME=${1} && echo "VMNAME=${1}" >> etc/virt-inst.cfg
#export DISC_SIZE=${2} && echo "${1}_DISC_SIZE=${2}" >> etc/virt-inst.cfg
#export VCPUS=${3} && echo "${1}_VCPUS=${3}" >> etc/virt-inst.cfg
#export RAM=${4} && echo "${1}_RAM=${4}" >> etc/virt-inst.cfg

# replace vars if they change for same vm name
#if [[ -n "${VMNAME}" ]];then
#      sed -i /VMNAME=/d etc/virt-inst.cfg
#      sed -i /${1}_DISC_SIZE=/d etc/virt-inst.cfg
#      sed -i /${1}_VCPUS=/d etc/virt-inst.cfg
#      sed -i /${1}_RAM=/d etc/virt-inst.cfg
#fi

UNIQ=${VMNAME}_$(date '+%s')

if [[ -z "${ORG}" ]]; [[ -z "${SERVER}" ]];then
  echo ""
  echo "You must set default values/arrays in ../etc/virt-inst.cfg"
  echo ""
  echo ""
  exit 1
fi

if [[ -f ks/network/"${VMNAME}".network ]];then
  echo "Kickstart config files in place.... OK"
  else
    echo "Kickstart config files are missing."
    echo "You must create files for %include."
    echo "Look in the uteeg/ks/* for examples on network, partitions, packages and post"
    echo
    echo "Also need uteeg/etc/hosts entry"
    exit 1
fi

curl -s --head http://"${SERVER}"/ks/rhel/Packages/repodata/ | grep "200 OK" || echo "have to run cd /var/www/html/uteeg/rhel/Packages && createrepo_c ." ||  exit 1

# Install httpd for ks, iso, manifest.zip
#rpm -q httpd || dnf -y install httpd
# open httpd to all if not already for ks and other activities later to be able to get to the libvirt host as an httpd server
firewall-cmd --list-all | grep -i services | grep nfs || firewall-cmd --permanent --add-service=httpd

# this will be the uniq ks.cfg file for building this vm
cat >> ./ks_${UNIQ}.cfg <<EOF
# Configure installation method
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/appe-kickstart-syntax-reference.html#sect-kickstart-commands-install
install
#trouble getting dns to work at boot, does not pick up from kickstart config yet. don't know where to add it in for virt-install at bottom. 
#url --mirrorlist="http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-26&arch=x86_64"
url --url ${URL}/${OS}
repo --name=redhat-internal --baseurl="http://${SERVER}/ks/apps/redhat" --cost=100
#repo --name=fedora-updates --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f26&arch=x86_64" --cost=100
repo --name=rpmfusion-free --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-26&arch=x86_64" --includepkgs=rpmfusion-free-release
repo --name=rpmfusion-free-updates --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-26&arch=x86_64" --includepkgs=rpmfusion-free-release
repo --name=rpmfusion-nonfree --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-26&arch=x86_64" --includepkgs=rpmfusion-nonfree-release
repo --name=rpmfusion-nonfree-updates --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-26&arch=x86_64" --includepkgs=rpmfusion-nonfree-release
repo --name=google-chrome --baseurl="http://dl.google.com/linux/chrome/rpm/stable/x86_64"
repo --name=insync --baseurl="http://yum.insynchq.com/fedora/$releasever/"
repo --name=rocketchat --baseurl="https://copr-be.cloud.fedoraproject.org/results/xenithorb/rocketchat-dev/fedora-$releasever-$basearch/"

# zerombr
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-zerombr.html
#zerombr

# Configure Boot Loader
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-bootloader.html
#bootloader --location=mbr --driveorder=vda

# Create Physical Partition
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-part.html
#part /boot --size=512 --asprimary --ondrive=vda --fstype=xfs
#part swap --size=10240 --ondrive=vda
#part / --size=8192 --grow --asprimary --ondrive=vda --fstype=xfs

# Remove all existing partitions
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-clearpart.html
#clearpart --all --drives=vda
# Partition clearing information
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
%include /tmp/${VMNAME}.partitions

# Configure Firewall
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-network-configuration.html#sect-kickstart-commands-firewall
firewall --enabled --ssh

# Configure Network Interfaces
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-network.html
#network --device=eth0 --bootproto=static --ip=10.0.0.18 --netmask=255.255.255.0 --gateway=10.0.0.1 --nameserver=10.0.0.1 --hostname=fedora-26.prayther.org
# Network information
%include /tmp/${VMNAME}.network


# Configure Keyboard Layouts
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-environment.html#sect-kickstart-commands-keyboard
keyboard --vckeymap=us --xlayouts='us'

# Configure Language During Installation
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-lang.html
lang en_US.UTF-8

# Configure X Window System
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-xconfig.html
xconfig --startxonboot

# Configure Time Zone
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-timezone.html
timezone America/New_York --isUtc

# Configure Authentication
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-users-groups.html#sect-kickstart-commands-auth
auth --enableshadow --passalgo=sha512

# Create User Account
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-user.html
#user --name=apraythe --password=password --plaintext --groups=wheel

# Set Root Password
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-rootpw.html
#rootpw --lock
rootpw --iscrypted \$6\$zBfR6/MikcoIX79Q\$G5Dv5HxUmsRrEOy2kTtrgO3o0rx7zNyvJWFhZpubxX9hhlH1bM7n9HW/6y6coDwsrO8qZssMRyxpdbSeSJoMO.

# Perform Installation in Text Mode
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-text.html
#text

# Package Selection
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-packages.html
%packages
-bluez

@core
@standard
@hardware-support
@base-x
@firefox
@fonts
@libreoffice
##@multimedia
@networkmanager-submodules
@printing
@gnome-desktop
@guest-desktop-agents
@workstation-product
fedora-productimg-workstation
@development-tools
vim
NetworkManager-openvpn
NetworkManager-openvpn-gnome
keepassx
#redshift-gtk
#gimp
##gnucash
##duplicity
##calibre
##irssi
#nmap
#tcpdump
#ansible
##thunderbird
#vlc
google-chrome-stable
#calc
#gitflow
gstreamer-plugins-ugly
gstreamer1-plugins-ugly
#redhat-rpm-config
#rpmconf
#strace
##wireshark
#ffmpeg
system-config-printer
#git-review
##gcc-c++
#readline-devel
##gcc-gfortran
##libX11-devel
##libXt-devel
##zlib-devel
##bzip2-devel
##lzma-devel
##xz-devel
##pcre-devel
##libcurl-devel
##python-virtualenvwrapper
##python-devel
##python3-devel
##golang
#libimobiledevice
#libimobiledevice-utils
#usbmuxd
#ifuse
##mariadb-server
transmission-gtk
#libffi-devel
redhat-internal-cert-install
redhat-internal-NetworkManager-openvpn-profiles
gnome-tweak-tool
insync
rocketchat-desktop
%end

# Post-installation Script
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-postinstall.html
%post
# Persist extra repos and import keys.
cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
rpm --import https://dl-ssl.google.com/linux/linux_signing_key.pub

rpm -ivh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-26.noarch.rpm
rpm -ivh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-26.noarch.rpm
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

# Reboot After Installation
# https://docs.fedoraproject.org/en-US/Fedora/26/html/Installation_Guide/sect-kickstart-commands-reboot.html
#reboot --eject
EOF
#this is very much setup for testing over and over... the same vm.
#so be very careful with the next few commands that destroy anything existing without confirmation.

#configure ansible
#rpm -q ansible || /usr/bin/yum install -y ansible
grep -i "${VMNAME}.${DOMAIN}" /etc/ansible/hosts || echo ["${VMNAME}"] >> /etc/ansible/hosts
grep -i "${VMNAME}.${DOMAIN}" /etc/ansible/hosts || echo "${VMNAME}.${DOMAIN}" >> /etc/ansible/hosts
#unregister so you don't make a mess on cdn
#ansible "${VMNAME}.${DOMAIN}" --timeout=5 -a "/usr/sbin/subscription-manager unregister"

virsh destroy "${VMNAME}"
virsh undefine "${VMNAME}"
rm -f /var/lib/libvirt/images/"${VMNAME}".qcow2
rm -f /var/lib/libvirt/images/"${VMNAME}".data.qcow2

#if the ip does not exist make a hosts entry into libvirt (dnsmasq) host so that the vm will resolve. important for satellite
grep -i "${IP}    ${VMNAME}.${DOMAIN} ${VMNAME}" /etc/hosts || echo "${IP}	${VMNAME}.${DOMAIN} ${VMNAME}" >> /etc/hosts

#virsh net-destroy ${NETWORK}
#virsh net-start ${NETWORK}

# just remove so ssh won't fail. ks/boot scripts put it back for a new vm later
sed -i /${VMNAME}/d /root/.ssh/known_hosts
sed -i /${VMNAME}/d /home/"${VIRTHOSTUSER}"/.ssh/known_hosts
sed -i /${IP}/d /root/.ssh/known_hosts
sed -i /${IP}/d /home/"${VIRTHOSTUSER}"/.ssh/known_hosts

#list of os-variant: osinfo-query os
#making an exception for virt 'name' and not os variant. doing host cpu passthru
if [[ $(echo ${VMNAME} | grep virt) ]];then
virt-install \
   --name="${VMNAME}" \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=50,sparse=false,format=qcow2,cache=none \
   --ram="${RAM}" \
   --cpu host-passthrough \
   --location=/var/lib/libvirt/images/"${RHEL_ISO}" \
   --os-type=linux \
   --noautoconsole --wait -1 \
   --os-variant=rhel"${OSVARIANT}" \
   --network network="${NETWORK}" \
   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${GATEWAY}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF}"
fi

if [[ "${OS}" = "rhel" ]];then
virt-install \
   --name="${VMNAME}" \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=50,sparse=false,format=qcow2,cache=none \
   --vcpus="${VCPUS}" --ram="${RAM}" \
   --location=/var/lib/libvirt/images/"${RHEL_ISO}" \
   --os-type=linux \
   --noautoconsole --wait -1 \
   --os-variant=rhel"${OSVARIANT}" \
   --network network="${NETWORK}" \
   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${GATEWAY}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF}"
fi

if [[ "${OS}" = "rhgf" ]];then
virt-install \
   --name="${VMNAME}" \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=150,sparse=false,format=qcow2,cache=none \
   --vcpus="${VCPUS}" --ram="${RAM}" \
   --location=/var/lib/libvirt/images/"${RHGS_ISO}" \
   --os-type=linux \
   --noautoconsole --wait -1 \
   --os-variant=rhel"${OSVARIANT}" \
   --network network="${NETWORK}" \
   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${GATEWAY}:${MASK}:${VMNAME}.${DOMAIN}:${NIC}:${AUTOCONF}"
fi
if [[ "${OS}" = "fedora" ]];then
virt-install \
   --name="${VMNAME}" \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".qcow2,size="${DISC_SIZE}",sparse=false,format=qcow2,cache=none \
   --disk path=/var/lib/libvirt/images/"${VMNAME}".data.qcow2,size=150,sparse=false,format=qcow2,cache=none \
   --vcpus="${VCPUS}" --ram="${RAM}" \
   --location=/var/lib/libvirt/images/"${FEDORA_ISO}" \
   --os-type=linux \
   --noautoconsole --wait -1 \
   --os-variant=fedora26 \
   --network network="${NETWORK}" \
   --extra-args ks="${URL}/ks_${UNIQ}.cfg ip=${IP}::${GATEWAY}:${MASK}:${VMNAME}.${DOMAIN}:ens3:${AUTOCONF} nameserver=${GATEWAY}"
fi
#   --os-variant=fedora"${OSVARIANT}" \
#   --network network="${NETWORK}",model=rtl8139 \

