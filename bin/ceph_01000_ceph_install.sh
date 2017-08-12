#!/bin/bash -x

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

#useradd ceph_ansible
#echo "password" | passwd "ceph_ansible" --stdin

#cat << EOF >/etc/sudoers.d/ceph_ansible
#ceph_ansible ALL = (root) NOPASSWD:ALL
#EOF

#chmod 0440 /etc/sudoers.d/ceph_ansible

# non interactive, emptly pass ""
su -c "ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa" ceph_ansible

# get everyone talking for ansible
for i in c d e
  do sshpass -p password ssh-copy-id -o StrictHostKeyChecking=no -i /home/ceph_ansible/.ssh/id_rsa.pub ceph_ansible@server"${i}"
     ssh -o StrictHostKeyChecking=no ceph_ansible@server"${i}" exit
done

#/bin/su -s /bin/bash -c "ssh -o StrictHostKeyChecking=no root@${GATEWAY} exit" foreman

yum -y install ceph-ansible

su -c "mkdir ~/ceph-ansible-keys" ceph_ansible
mv /etc/ansible /etc/ansible.off
cp /usr/share/ceph_ansible/site.yml.sample /usr/share/ceph_ansible/site.yml
ln -s /usr/share/ceph-ansible /etc/ansible
#cp /usr/share/ceph_ansible/site.yml.sample /etc/ansible/site.yml
#cp /etc/ansible/group_vars/all.yml.sample /etc/ansible/group_vars/all.yml
#cp /etc/ansible/group_vars/mons.yml.sample /etc/ansible/group_vars/mons.yml

cat << EOF > /etc/ansible/hosts
[mons]
server[c:e]

[osds]
server[c:e]
EOF

cat << EOF1 > /usr/share/ceph-ansible/group_vars/all.yml
---
# Variables here are applicable to all host groups NOT roles

###########
# GENERAL #
###########

fetch_directory: /home/ceph_ansible/eph-ansible-keys

###########
# INSTALL #
###########

mon_group_name: mons
osd_group_name: osds
rgw_group_name: rgws
mds_group_name: mdss
check_firewall: False

ceph_rhcs: "{{ ceph_stable_rh_storage | default(true) }}"
ceph_rhcs_cdn_install: "{{ ceph_stable_rh_storage_cdn_install | default(true) }}" # assumes all the nodes can connect to cdn.redhat.com

######################
# CEPH CONFIGURATION #
######################
fsid: "{{ cluster_uuid.stdout }}"
generate_fsid: true

cephx: true
max_open_files: 131072

monitor_interface: eth0
mon_use_fqdn: false # if set to true, the MON name used will be the fqdn in the ceph.conf

## OSD options
journal_size: 5120 # OSD journal size in MB
public_network: 10.0.0.0/24
cluster_network: "{{ public_network }}"
osd_mkfs_type: xfs
osd_mkfs_options_xfs: -f -i size=2048
osd_mount_options_xfs: noatime,largeio,inode64,swalloc
osd_objectstore: filestore

###################
# CONFIG OVERRIDE #
###################

 ceph_conf_overrides:
   global:
         mon_initial_members: serverc,serverd,servere
    mon_host: 172.25.250.12,172.25.250.13,172.25.250.14
    mon_osd_allow_primary_affinity: true
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_pg_warn_min_per_osd: 0
    mon_pg_warn_max_per_osd: 0
    mon_pg_warn_max_object_skew: 0
  client:
    rbd_default_features: 1
    rbd_default_format: 2
    rbd_cache: "true"
    rbd_cache_writethrough_until_flush: "false"
EOF1

cat << EOF2 > /etc/ansible/group_vars/mons.yml
###########
# GENERAL #
###########
fetch_directory: /usr/share/ceph-ansible/group_vars/mons.yml

mon_group_name: mons

fsid: "{{ cluster_uuid.stdout }}"
monitor_secret: "{{ monitor_keyring.stdout }}"
cephx: true
EOF2

cat << EOF3 > /etc/ansible/group_vars/osds.yml
---
###########
# GENERAL #
###########

fetch_directory: /home/ceph_ansible/ceph-ansible-keys

##############
# CEPH OPTIONS
##############
# ACTIVATE THE FSID VARIABLE FOR NON-VAGRANT DEPLOYMENT
fsid: "{{ cluster_uuid.stdout }}"
cephx: true

# Declare devices
# All the scenario inherit from the following device declaration
#
devices:
  - /dev/vdb
#   - /dev/vdc
#   - /dev/vdd

# I. First scenario: journal and osd_data on the same device
# Use 'true' to enable this scenario
# This will collocate both journal and data on the same disk
# creating a partition at the beginning of the device

journal_collocation: true
EOF3
#wget -P /root/ --no-clobber http://${SERVER}/ks/iso/${SATELLITE_ISO}
#wget -P /root/ --no-clobber http://${SERVER}/ks/iso/${RHEL_ISO}

# Create Repository for Local install
#dvd_repo () { cat << EOF > /etc/yum.repos.d/rhel-dvd.repo
#[rhel]
#name=RHEL local
#baseurl=file:///mnt/rhel
#enabled=1
#gpgcheck=1
#EOF
#}
#doit dvd_repo

# If you a disconnected from internet and also for speed
#ls /mnt/rhel || mkdir /mnt/rhel
#mount -o loop /root/${RHEL_ISO} /mnt/rhel
#ls /mnt/sat || mkdir /mnt/sat
#mount -o loop /root/${SATELLITE_ISO} /mnt/sat
#doit /mnt/sat/install_packages

#doit /usr/bin/firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
# --add-port="67/udp" --add-port="69/udp" \
# --add-port="80/tcp"  --add-port="443/tcp" \
# --add-port="5647/tcp" \
# --add-port="8000/tcp" --add-port="8140/tcp"
#doit firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
# --add-port="67/udp" --add-port="69/udp" \
# --add-port="80/tcp"  --add-port="443/tcp" \
# --add-port="5647/tcp" \
# --add-port="8000/tcp" --add-port="8140/tcp"

#katello-service status || satellite-installer --scenario satellite \
#--foreman-initial-organization "${ORG}" \
#--foreman-initial-location "${LOC}" \
#--foreman-admin-username admin \
#--foreman-admin-password password \
#--foreman-proxy-tftp true \
#--foreman-proxy-tftp-servername $(hostname) \
#--capsule-puppet false \
#--foreman-proxy-dns-managed=false \
#--foreman-proxy-dhcp-managed=false

#export VMNAME=$(echo "$(hostname)" | awk -F"." '{print $1}')
#grep "^${VMNAME}" ../etc/virt-inst.cfg || echo VMNAME=$(hostname) | awk -F"." '{print $1}' >> ../etc/virt-inst.cfg
#mkdir  ~/.hammer
#hammer_cli_config () { cat << EOF > ~/.hammer/cli_config.yml
#   :foreman:
#       :host: https://${VMNAME}.${DOMAIN}
#       :username: ${ADMIN}
#       :password: ${PASSWD}
#       :organization: ${ORG}
#EOF
#}
#hammer_cli_config

#mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
#mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.off

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
