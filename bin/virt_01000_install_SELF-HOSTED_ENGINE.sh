#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
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
export HOME=/root


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
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "virt" ]];then
 echo ""
 echo "Need to run this on the 'virt' node"
 echo ""
 exit 1
fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

#https://fedoraproject.org/wiki/How_to_enable_nested_virtualization_in_KVM. Actually type 'host-passthrough" in the cpu type as outlined on web page. this makes nested virt work after enabling on the virthost/kvm
#make sure you have setup your virt host (libvirt/kernel boot options) to enable nested virtualization. https://fedoraproject.org/wiki/How_to_enable_nested_virtualization_in_KVM
#https://techglimpse.com/enable-nested-virtualization-support-virt-manager/
yum -y install sendmail mutt dns-server
#wget -P /root/ --no-clobber http://${SERVER}/ks/iso/rhvm-appliance-4.1.20170811.0-1.el7.noarch.rpm
#rpm -Uvh /root/rhvm-appliance-4.1.20170811.0-1.el7.noarch.rpm
wget -P /usr/share/ovirt-engine-appliance/ http://${SERVER}/ks/apps/rhev/rhvm-appliance-20170914.0-1.x86_64.rhevm.ova
systemctl enable sendmail
systemctl start sendmail

mkdir /var/tmp/data
mkdir /var/tmp/iso
mkdir /var/tmp/export
mkdir /var/tmp/nfs
chown vdsm.kvm /var/tmp/data /var/tmp/iso /var/tmp/export /var/tmp/nfs
grep "var/tmp/data" /etc/exports || echo "/var/tmp/data *(rw,no_acl)" >> /etc/exports
grep "var/tmp/iso " /etc/exports || echo "/var/tmp/iso *(rw,no_acl)" >> /etc/exports
grep "var/tmp/export " /etc/exports || echo "/var/tmp/export *(rw,no_acl)" >> /etc/exports
grep "var/tmp/nfs " /etc/exports || echo "/var/tmp/nfs *(rw,no_acl)" >> /etc/exports
systemctl restart nfs-server
#echo "/dev/vdb1               /var/tmp/vdb1               xfs     defaults        0 0" >> /etc/fstab
#mount -a

cat << EOF > /root/hosted-engine-answer-file.txt
[environment:default]
OVEHOSTED_CORE/rollbackProceed=none:None
OVEHOSTED_CORE/screenProceed=none:None
OVEHOSTED_CORE/deployProceed=bool:True
OVEHOSTED_CORE/upgradeProceed=none:None
OVEHOSTED_CORE/confirmSettings=bool:True
OVEHOSTED_NETWORK/fqdn=str:virt-host.prayther.org
OVEHOSTED_NETWORK/bridgeName=str:ovirtmgmt
OVEHOSTED_NETWORK/firewallManager=str:iptables
OVEHOSTED_NETWORK/gateway=str:10.0.0.1
OVEHOSTED_ENGINE/insecureSSL=none:None
OVEHOSTED_ENGINE/clusterName=str:Default
OVEHOSTED_STORAGE/storageDatacenterName=str:hosted_datacenter
OVEHOSTED_STORAGE/domainType=str:nfs4
OVEHOSTED_STORAGE/connectionUUID=str:deeb3aec-3f5c-433e-8af8-eba37f2da263
OVEHOSTED_STORAGE/LunID=none:None
OVEHOSTED_STORAGE/imgSizeGB=str:58
OVEHOSTED_STORAGE/var/tmpOptions=none:None
OVEHOSTED_STORAGE/iSCSIPortalIPAddress=none:None
OVEHOSTED_STORAGE/metadataVolumeUUID=str:4e62f05c-ebab-4799-9421-1a9ed8c80bfa
OVEHOSTED_STORAGE/sdUUID=str:c8d79cdc-56e0-489d-81d5-9d307f5cd24a
OVEHOSTED_STORAGE/iSCSITargetName=none:None
OVEHOSTED_STORAGE/metadataImageUUID=str:0bc49c57-4404-4d8e-8542-56ad4aa46b5f
OVEHOSTED_STORAGE/lockspaceVolumeUUID=str:f15f5cab-b4e5-4c2f-b9e4-a3258e114da3
OVEHOSTED_STORAGE/iSCSIPortalPort=none:None
OVEHOSTED_STORAGE/imgUUID=str:091ee596-86c7-46a7-80ad-e3d50615b21a
OVEHOSTED_STORAGE/confImageUUID=str:4ec248f4-e882-4d61-87f3-59945a6d9142
OVEHOSTED_STORAGE/spUUID=str:00000000-0000-0000-0000-000000000000
OVEHOSTED_STORAGE/lockspaceImageUUID=str:f60a7a6e-37cf-4814-be8c-574fa12a5b0b
OVEHOSTED_ENGINE/enableHcGlusterService=none:None
OVEHOSTED_STORAGE/storageDomainName=str:hosted_storage
OVEHOSTED_STORAGE/iSCSIPortal=none:None
OVEHOSTED_STORAGE/volUUID=str:c272fb18-c087-4a07-9b06-bf019c3e46aa
OVEHOSTED_STORAGE/vgUUID=none:None
OVEHOSTED_STORAGE/confVolUUID=str:874f5827-b78c-412c-abd9-acbc42734f43
OVEHOSTED_STORAGE/storageDomainConnection=str:localhost:/var/tmp/nfs
OVEHOSTED_STORAGE/iSCSIPortalUser=none:None
OVEHOSTED_VDSM/consoleType=str:vnc
OVEHOSTED_VM/vmMemSizeMB=int:5245
OVEHOSTED_VM/vmUUID=str:c2ac111b-00e5-43c6-b4ef-ede5ff1c5723
OVEHOSTED_VM/vmMACAddr=str:00:16:3e:75:f4:85
OVEHOSTED_VM/emulatedMachine=str:pc-i440fx-rhel7.3.0
OVEHOSTED_VM/consoleUUID=str:771feb49-bf8e-43de-8087-851c2ef5fc00
OVEHOSTED_VM/vmVCpus=str:4
OVEHOSTED_VM/nicUUID=str:6f3eb375-8bd5-4169-98d0-882b4ad5f1bc
OVEHOSTED_VM/cdromUUID=str:dea377d1-1e08-4b65-90cd-ac6c82bae697
OVEHOSTED_VM/ovfArchive=str:/usr/share/ovirt-engine-appliance/rhvm-appliance-20170914.0-1.x86_64.rhevm.ova
OVEHOSTED_VM/vmCDRom=none:None
OVEHOSTED_VM/automateVMShutdown=bool:True
OVEHOSTED_VM/cloudInitISO=str:generate
OVEHOSTED_VM/cloudinitInstanceDomainName=str:prayther.org
OVEHOSTED_VM/cloudinitInstanceHostName=str:virt-host.prayther.org
OVEHOSTED_VM/rootSshPubkey=str:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqzz0IIJsnncRvTqrK8QM4y3Gt2I/c/GnW1pqFXst/uZGU14MxJSZsuFK5Xs7/GwpKPoDv9mwzUTs6Q4l5Pj8dHlwiJLjbFPi89Ri1kmV225+Tu+KgVO7q300kI5IknT4qpUKdlScAdSPm0mwJ6pb01hdc5iNKmGK8sEOkty+3nj7lbcXX1lR6NF2FmNaOn02c9ZKgun7uejJ2mplrIk/KR4AzMk9y0kuLhPpk1LDtitBKD2wpUTCh75C7j6GSe8BRGigvlcCBESZp7rCCoiAklhR9LcO0u9SaxHMnQpKmnQfLe3GMx7zJdJd0aD9XrvgG0aueZV0O7c9pAv+FETDD root@fedora.prayther.laptop
OVEHOSTED_VM/cloudinitExecuteEngineSetup=bool:True
OVEHOSTED_VM/cloudinitVMStaticCIDR=str:10.0.0.16/24
OVEHOSTED_VM/cloudinitVMTZ=str:America/New_York
OVEHOSTED_VM/rootSshAccess=str:yes
OVEHOSTED_VM/cloudinitVMETCHOSTS=bool:False
OVEHOSTED_VM/cloudinitVMDNS=str:10.0.0.1
OVEHOSTED_VDSM/spicePkiSubject=str:C=EN, L=Test, O=Test, CN=Test
OVEHOSTED_VDSM/pkiSubject=str:/C=EN/L=Test/O=Test/CN=Test
OVEHOSTED_VDSM/caSubject=str:/C=EN/L=Test/O=Test/CN=TestCA
OVEHOSTED_VDSM/cpu=str:model_Haswell-noTSX
OVEHOSTED_NOTIF/smtpPort=str:25
OVEHOSTED_NOTIF/smtpServer=str:localhost
OVEHOSTED_NOTIF/sourceEmail=str:root@localhost
OVEHOSTED_NOTIF/destEmail=str:root@localhost
EOF

#screen -m bash -c 'hosted-engine --deploy; exec bash'
screen -m bash -c 'hosted-engine --deploy --config-append=/root/hosted-engine-answer-file.txt; exec bash'

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
