#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

cd /root && wget --no-clobber http://${SERVER}/ks/iso/${SATELLITE_ISO}
cd /root && wget --no-clobber http://${SERVER}/ks/iso/${RHEL_ISO}
#cd /root && wget --no-clobber http://${SERVER}/ks/manifest/manifest.zip

# Create Repository for Local install
cat << EOF > /etc/yum.repos.d/rhel-dvd.repo
[rhel]
name=RHEL local
baseurl=file:///mnt/rhel
enabled=1
gpgcheck=1
EOF

# If you a disconnected from internet and also for speed
mkdir /mnt/rhel
mount -o loop /root/${RHEL_ISO} /mnt/rhel
mkdir /mnt/sat
mount -o loop /root/${SATELLITE_ISO} /mnt/sat
cd /mnt/sat
./install_packages
cd /tmp

/usr/bin/firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="69/udp" \
 --add-port="80/tcp"  --add-port="443/tcp" \
 --add-port="5647/tcp" \
 --add-port="8000/tcp" --add-port="8140/tcp"
firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="69/udp" \
 --add-port="80/tcp"  --add-port="443/tcp" \
 --add-port="5647/tcp" \
 --add-port="8000/tcp" --add-port="8140/tcp"

# if you are disconnected you are installing from RHEL/Satellite DVD's
# if you are connected the *register*.sh script will have subscribed and updated everything already
/usr/sbin/satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-initial-location "${LOC}" \
--foreman-admin-username admin \
--foreman-admin-password password \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-servername $(hostname) \
--capsule-puppet false

mkdir  ~/.hammer
cat << EOF > ~/.hammer/cli_config.yml
   :foreman:
       :host: https://${VMNAME}.${DOMAIN}
       :username: ${ADMIN}
       :password: ${PASSWD}
       :organization: ${ORG}
EOF

mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.off

/usr/bin/yum clean all
/usr/bin/yum -y update
