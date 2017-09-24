export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

source lib/bsfl/lib/bsfl.sh
#DEBUG=yes
source etc/virt-inst.cfg

if [ -z "${1}" ];then
  echo ""
  echo " ./virt-install.sh <vmname>"
  echo ""
  echo "You need to configure a vm in uteeg/etc/hosts"
  echo "Use an example in uteeg/etc/hosts"
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

# Install httpd for ks, iso, manifest.zip, nfs-utils for satellite export. using some ansible
install_libvirt_host_resources () {
rpm -q ansible virt-manager virt-install virt-viewer nfs-utils httpd
}
cmd install_libvirt_host_resources || msg_error "Line $LINENO: rpm -q ansible virt-manager virt-install virt-viewer nfs-utils httpd"

#this set vars per vm from hosts file based on $1, vmname used to launch this script
inputfile=./etc/hosts
cmd "VMNAME=$(awk /"${1}"/'{print $1}' "${inputfile}")"
cmd "DISC_SIZE=$(awk /"${1}"/'{print $2}' "${inputfile}")"
cmd "VCPU=$(awk /"${1}"/'{print $3}' "${inputfile}")"
cmd "RAM=$(awk /"${1}"/'{print $4}' "${inputfile}")"
cmd "IP=$(awk /"${1}"/'{print $5}' "${inputfile}")"
cmd "OS=$(awk /"${1}"/'{print $6}' "${inputfile}")"
cmd "RHVER=$(awk /"${1}"/'{print $7}' "${inputfile}")"
cmd "OSVARIANT=$(awk /"${1}"/'{print $8}' "${inputfile}")"
#vmname needs to have the structure:
#sat-*
#ceph-*
#gfs-*
#PRODUCT=$(echo "${VMNAME}" | awk -F"-" '{print $1}')

cmd "grep "^DocumentRoot" /etc/httpd/conf/httpd.conf" || msg_error "Line $LINENO: Looking for ^DocumentRoot /etc/httpd/conf/httpd.conf Need to install httpd and put uteeg in /var/www/html/uteeg. For some dumb reason I setup ln -s uteeg ks also."
cmd "file /var/www/html/uteeg" || msg_error "Line $LINENO: Just put uteeg under /var/www/html. And create ln -s uteeg ks"
cmd "file /var/www/html/ks" || msg_error "Line $LINENO: Just put ks link under /var/www/html. And create ln -s uteeg ks"

exit 4

cmd "UNIQ=${VMNAME}_$(date '+%s')"

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

#curl -s --head http://"${SERVER}"/ks/rhel/Packages/repodata/ | grep "200 OK" || echo "have to run cd /var/www/html/uteeg/rhel/Packages && createrepo_c ." ||  exit 1
ls /var/www/html/ks/rhel/Packages/repodata/ || error_exit "Line $LINENO: have to run cd /var/www/html/uteeg/rhel/Packages && createrepo_c ."

# Install httpd for ks, iso, manifest.zip
#rpm -q httpd || dnf -y install httpd
# open httpd to all if not already for ks and other activities later to be able to get to the libvirt host as an httpd server
#firewall-cmd --get-default-zone
#firewall-cmd --get-service #lists all service avail. not just enabled

firewall-cmd --list-all | grep -i services | grep http || firewall-cmd --permanent --add-service=http && firewall-cmd --reload

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
grep -i "${IP} ${VMNAME}.${DOMAIN} ${VMNAME}" /etc/hosts || echo "${IP} ${VMNAME}.${DOMAIN} ${VMNAME}" >> /etc/hosts

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
