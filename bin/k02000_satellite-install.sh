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


doit wget -P /root/ --no-clobber http://${SERVER}/ks/iso/${SATELLITE_ISO}
doit wget -P /root/ --no-clobber http://${SERVER}/ks/iso/${RHEL_ISO}
#cd /root && wget --no-clobber http://${SERVER}/ks/manifest/manifest.zip

# Create Repository for Local install
dvd_repo () { cat << EOF > /etc/yum.repos.d/rhel-dvd.repo
[rhel]
name=RHEL local
baseurl=file:///mnt/rhel
enabled=1
gpgcheck=1
EOF
}
doit dvd_repo

# If you a disconnected from internet and also for speed
doit mkdir /mnt/rhel
doit mount -o loop /root/${RHEL_ISO} /mnt/rhel
doit mkdir /mnt/sat
doit mount -o loop /root/${SATELLITE_ISO} /mnt/sat
doit /mnt/sat/install_packages

doit /usr/bin/firewall-cmd --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="69/udp" \
 --add-port="80/tcp"  --add-port="443/tcp" \
 --add-port="5647/tcp" \
 --add-port="8000/tcp" --add-port="8140/tcp"
doit firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" \
 --add-port="67/udp" --add-port="69/udp" \
 --add-port="80/tcp"  --add-port="443/tcp" \
 --add-port="5647/tcp" \
 --add-port="8000/tcp" --add-port="8140/tcp"

# if you are disconnected you are installing from RHEL/Satellite DVD's
# if you are connected the *register*.sh script will have subscribed and updated everything already
doit /usr/sbin/satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-initial-location "${LOC}" \
--foreman-admin-username admin \
--foreman-admin-password password \
--foreman-proxy-tftp true \
--foreman-proxy-tftp-servername $(hostname) \
--capsule-puppet false

doit export VMNAME=$(echo "$(hostname)" | awk -F"." '{print $1}')
doit grep "${VMNAME}" ../etc/virt-inst.cfg || doit echo VMNAME=$(hostname) | awk -F"." '{print $1}' >> ../etc/virt-inst.cfg
doit mkdir  ~/.hammer
hammer_cli_config () { cat << EOF > ~/.hammer/cli_config.yml
   :foreman:
       :host: https://${VMNAME}.${DOMAIN}
       :username: ${ADMIN}
       :password: ${PASSWD}
       :organization: ${ORG}
EOF
}
doit hammer_cli_config

doit mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
doit mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.off

doit /usr/bin/yum clean all
doit /usr/bin/yum -y update
