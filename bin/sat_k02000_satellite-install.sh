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


wget -nv -P /root/ --no-clobber http://${SERVER}/ks/iso/${SATELLITE_ISO}
wget -nv -P /root/ --no-clobber http://${SERVER}/ks/iso/${RHEL_ISO}

git clone https://github.com/RedHatSatellite/satellite-sanity.git /root/satellite-sanity
git clone https://github.com/RedHatSatellite/katello-cvmanager.git

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
ls /mnt/rhel || mkdir /mnt/rhel
mount -o loop $(ls /root/rhel*latest*.iso) /mnt/rhel
ls /mnt/sat || mkdir /mnt/sat
mount -o loop $(ls /root/sat*latest*.iso) /mnt/sat
doit /mnt/sat/install_packages

doit /usr/bin/firewall-cmd \
	--add-port="53/udp" --add-port="53/tcp" \
--add-port="67/udp" --add-port="69/udp" \
--add-port="80/tcp"  --add-port="443/tcp" \
--add-port="5000/tcp" --add-port="5647/tcp" \
--add-port="8000/tcp" --add-port="8140/tcp" \
--add-port="9090/tcp"
doit firewall-cmd --runtime-to-permanent

#katello-service status || satellite-installer --scenario satellite \
#satellite-installer --scenario satellite \
#--foreman-initial-organization "${ORG}" \
#--foreman-initial-location "${LOC}" \
#--foreman-admin-username admin \
#--foreman-admin-password password \
#--foreman-proxy-tftp true \
#--foreman-proxy-tftp-servername $(hostname) # --foreman-proxy-puppetca true \ # =sat63 "--capsule-puppet true \ =sat62"
#--foreman-proxy-dns-managed=false \
#--enable-foreman-plugin-openscap \
#--foreman-proxy-dhcp-managed=false

satellite-installer --scenario satellite \
--foreman-initial-organization "${ORG}" \
--foreman-initial-location "${LOC}" \
--foreman-admin-username admin \
--foreman-admin-password password \
--foreman-proxy-puppetca true \
--foreman-proxy-tftp true \
--enable-foreman-plugin-discovery

export VMNAME=$(echo "$(hostname)" | awk -F"." '{print $1}')
grep "^${VMNAME}" ../etc/virt-inst.cfg || echo VMNAME=$(hostname) | awk -F"." '{print $1}' >> ../etc/virt-inst.cfg
mkdir  ~/.hammer
hammer_cli_config () { cat << EOF > ~/.hammer/cli_config.yml
   :foreman:
       :host: https://${VMNAME}.${DOMAIN}
       :username: ${ADMIN}
       :password: ${PASSWD}
       :organization: ${ORG}
EOF
}
hammer_cli_config

mv /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.off
mv /etc/yum.repos.d/satellite-local.repo /etc/yum.repos.d/satellite-local.repo.off

#yum -y install puppet-foreman_scap_client
#foreman-rake foreman_openscap:bulk_upload:default
#mkdir -p /etc/puppet/environments/production/modules

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
