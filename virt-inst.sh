#!/bin/bash -x

if [ "${1}" == "" ];then
  echo ""
  echo " ./virt-install.sh <vmname> <disc in GB> <vcpus> <ram>"
  echo ""
  echo "Run from current dir /var/www/html/ks"
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

NAME=$1
#DISC_SIZE=100
DISC_SIZE=$2
DOMAIN=prayther.laptop
UNIQ=${NAME}_$(date '+%s') 
#URL=http://192.168.122.1/ks
URL=http://10.0.0.1/ks
# Use default for dhcp, laptoplab or homelab for non dhcp, because satellite or idm is providing dns
#NETWORK=default
NETWORK=laptoplab
IP=10.0.0.8
MASK=255.255.255.0
GATEWAY=10.0.0.1
NIC=eth0
AUTOCONF=none
#VCPUS=2
VCPUS=$3
#RAM=4096
RAM=$4
DISC=vda
OS=rhel
OSVER=7
OSVERSION=7.3
ORG=prayther
LOC=laptop

cat >> ./ks_${UNIQ}.cfg <<EOF
# System authorization information
reboot
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
#cdrom
url --url http://${GATEWAY}/ks/${OS}${OSVERSION}
# Use graphical install
text
# Run the Setup Agent on first boot
firstboot --disable
ignoredisk --only-use=$DISC
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
%include /tmp/network

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
%include /tmp/partitions

repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64

%packages
@core
wget
vim
bind-utils
# ansible comes from epel. so install it after reboot in post
#ansible
deltarpm
%include /tmp/packages
%end

%pre
#!/bin/bash
hostname=""
set -- `cat /proc/cmdline`
for I in $*; do case "$I" in *=*) eval $I;; esac; done

curl http://${GATEWAY}/ks/network/${NAME} > /tmp/network
#curl http://${GATEWAY}/ks/post/${NAME}.sh > /tmp/${NAME}.sh
curl http://${GATEWAY}/ks/partitions/${NAME} > /tmp/partitions
curl http://${GATEWAY}/ks/packages/${NAME} > /tmp/packages
%end

#%include /tmp/post

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end

%post
# Backup the original rc.local file... empty
cp /etc/rc.local /etc/rc.local.orig

# step one creat a file to run by rc.local at next boot
cat <<'EOFKS' > /etc/rc.local.ks.sh
#!/bin/bash -x

#Copy over the main script for configuration
cd /root && wget http://${GATEWAY}/ks/post/${NAME}.sh
chmod 700 /root/${NAME}.sh

mkdir /root/.ssh
chmod 700 /root/.ssh

cat <<'ROOTSSHKEY' > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqzz0IIJsnncRvTqrK8QM4y3Gt2I/c/GnW1pqFXst/uZGU14MxJSZsuFK5Xs7/GwpKPoDv9mwzUTs6Q4l5Pj8dHlwiJLjbFPi89Ri1kmV225+Tu+KgVO7q300kI5IknT4qpUKdlScAdSPm0mwJ6pb01hdc5iNKmGK8sEOkty+3nj7lbcXX1lR6NF2FmNaOn02c9ZKgun7uejJ2mplrIk/KR4AzMk9y0kuLhPpk1LDtitBKD2wpUTCh75C7j6GSe8BRGigvlcCBESZp7rCCoiAklhR9LcO0u9SaxHMnQpKmnQfLe3GMx7zJdJd0aD9XrvgG0aueZV0O7c9pAv+FETDD root@fedora.prayther.laptop
ROOTSSHKEY
chmod 400 /root/.ssh/authorized_keys

cat <<'ID_RSA' > /root/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAys1szr+3WRpYdVVrj+vB54N++GXpkj0+dLXUsFwV1PZK5HjW
xcAovYoiW+6iKjBX/ZAVguSXy1Bq85Lkw5JRaETPE2Y9QtWo9gY6ExOsRaB7JXT6
80To/DKmBcpDV2LitLoFj1OTRR9oz3NUq3e8CrfTmAf9qs9uGoyX/rt86OZJNWYr
XbHn4KObGJ+1AXVBslx8Nfw4bPLR24FQO8Ja0shIeoJrqptXU2ZKYvvqRWi3qF/D
qjZVScDzAXnmIUpj6lyciw8PK9c++G+mZiqkC48hokDNVg2QidMtCr8eFT2GJaSL
oCUupc83bgXJ3LHw3nqpg7pmEk7VEPTgIBMscwIDAQABAoIBAQCZ1E5XWObLSIeW
oK+RIIQZhw3VfwA3tAre3lmxWHga7KMMQHiw0TxV4SSE1TLei4MCy7r1aU2Wo64s
idzKV/819xOXpHKNcqHR1BFTDRYcTkl6tQvxYPDU89opBC4mZ9SMv5meCQfpY5TN
3q53zb+t5ZgzdsQ8P1FGBCT6zN5HjaNHbVf3EM2CuonBPoVg8Jp8sJAkhZ8a/0dM
7tYNiWnv1KrobbCBGuUtbNj0QfJDpfz/AGqofCI8z+vGSLes7wKxvcAKhpWgdnCb
sBJUwddfE0HaUw4Sf/gcwlKN507wJPfgOevV6KXgfwteL9oKC9FznT4+GDE/d4+/
nxtw7LERAoGBAPgiLIst8Ife5WyNWhW700xKPtptFfmVnDzAMWW/mW2MQT8Hla71
/CwqehSg1qvA9Dt+rQJ3vOTO4DfXoCMG+z+S0LOYOwzB3d2s7/NjQdAVhR4B7BYk
VPQL5h9vf77dh6D97q4qDlo27guP3f4qSUSvXy6CG+BFLTtgG4g9g3drAoGBANE7
WU9qXwbocRzyyod87lEwgM/qeiIaL3KmBTlM3K1PGpgwi92AFO/nriCrZ5YA8wWQ
V10QzRakgfuSDwqzpnKmjUvedSZj1dSzVH4dJYsFLmxijgfLpb1JeS/cjBqxSBI1
nFUMzgydx2XBT3vYXQbC0dRL3xgD48LHpIGiTUkZAoGBAKnPKVCuRbeWMMfTDF1n
Rrkk7lKo6Kr/WgaxOJz7PFKd82DhHey4ZrUK9LT9RSwRRpMYo+nWa6zibsuIgwy1
kGf3X2Aow/B9FArKeQPFX5q5v3nDsv+MKZ9CLWBB+9hw3oqsfRUvrtbKVKoQ8Mkp
wy6AHdFENTOL4+KIaQ8Zmci1AoGAVOqHVqnPI1iW/66x78cOWbkbrkZ1hv2loBwt
JpJBRb1DB908BouC89LNYsjt431DJFDuhADbm4LslhMzM56xwPpDgjUoyoneMNMP
SZe+sutJagedqSBHhckZ/AjAe9zTaUCE0CfAQHKQiIWqIpMvPh03V7frNS3u9BBe
fZZHU5ECgYBYZUteZSX4uNahAhXdsYf0vHDVJ4e6Z+ju2GUh0MMkI0PdWJKyVkXz
u2GAE2G6RRsXFXi0GV0VtFsWmDZ1918YIYcvx6cc9Sv5WRSxXCpkzd11tAVSsmbO
jJmTpxI+UaDnZ3FGcjXuwZtQIaYAOpj1aXJMeoMsW0aeVaaU9thhfA==
-----END RSA PRIVATE KEY-----
ID_RSA
chmod 600 /root/.ssh/id_rsa

cat <<'ID_RSAPUB' > /root/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKzWzOv7dZGlh1VWuP68Hng374ZemSPT50tdSwXBXU9krkeNbFwCi9iiJb7qIqMFf9kBWC5JfLUGrzkuTDklFoRM8TZj1C1aj2BjoTE6xFoHsldPrzROj8MqYFykNXYuK0ugWPU5NFH2jPc1Srd7wKt9OYB/2qz24ajJf+u3zo5kk1Zitdsefgo5sYn7UBdUGyXHw1/Dhs8tHbgVA7wlrSyEh6gmuqm1dTZkpi++pFaLeoX8OqNlVJwPMBeeYhSmPqXJyLDw8r1z74b6ZmKqQLjyGiQM1WDZCJ0y0Kvx4VPYYlpIugJS6lzzduBcncsfDeeqmDumYSTtUQ9OAgEyxz root@sat.laptop.prayther
ID_RSAPUB
chmod 644 /root/.ssh/id_rsa.pub

EOFKS

# step 2 backup the ks stuff and put the orig rc.local in place and reboot again
cat <<'EOFKS1' > /etc/rc.local
#!/bin/bash -x
/etc/rc.local.ks.sh
cp /etc/rc.local /tmp/
cp /etc/rc.local.ks.sh /tmp/
cp /etc/rc.local.orig /etc/rc.local
/sbin/reboot
EOFKS1

chmod 0755 /etc/rc.local.ks.sh
chmod 0755 /etc/rc.local
%end
EOF

ansible sat --timeout=5 -a "/usr/sbin/subscription-manager unregister"

virsh destroy sat
virsh undefine sat
rm -rf /var/lib/libvirt/images/sat.qcow2

virsh net-destroy ${NETWORK}
virsh net-start ${NETWORK}

/bin/sed -i /${NAME}/d /root/.ssh/known_hosts
/bin/sed -i /${NAME}/d /home/apraythe/.ssh/known_hosts

virt-install \
   --name=${NAME} \
   --disk path=/var/lib/libvirt/images/${NAME}.qcow2,size=${DISC_SIZE},sparse=false,format=qcow2,cache=none \
   --vcpus=${VCPUS} --ram=${RAM} \
   --location=/var/lib/libvirt/images/rhel-server-${OSVERSION}-x86_64-dvd.iso \
   --os-type=linux \
   --os-variant=rhel${OSVERSION} \
   --network network=${NETWORK} \
   --extra-args ks="http://${GATEWAY}/ks/ks_${UNIQ}.cfg ip=${IP}::${GATEWAY}:${MASK}:${NAME}.${DOMAIN}:${NIC}:${AUTOCONF}"


#until ansible sat -a "echo Alive!"
#  do
#        echo "Waiting for server to come up ${NAME}"
# done

  #ansible sat -a "/usr/sbin/subscription-manager --username= --password=
  #ansible sat -a "/usr/sbin/subscription-manager attach --pool=8a85f9873f77744e013f8944ab87680b"
  #ansible sat -a "/usr/sbin/subscription-manager repos '--disable=*'"
  #ansible sat -a "/usr/sbin/subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.2-rpms"
  #ansible sat -a "yum repolist"
  #ansible sat -a "yum -y update"
  #ansible sat -a "yum -y install satellite"
  #ansible sat -a "reboot"