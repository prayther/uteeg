#!/bin/bash -x

# this script broke at last fedora 26 update of qemu* packages
# did some trouble shooting, removing all but the 'hammer host create'
# and then adding the cdrom manually and it still just flickers on the boot screen
# created a vm manually in virt-manager and set the mac on the host for satellite and that worked
# it made me think it was how satellite is interacting with libvirt compute resource
# hope this will just start magically working again.
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

#runs or not based on hostname; ceph-?? gfs-??? sat-???
#if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "gfs" ]];then
# echo ""
# echo "Need to run this on the 'gfs' node"
# echo ""
# exit 1
#fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

katello-service status
if [[ ${?} != "0" ]];then
        echo "Either this is not a Satellite, or you have an error on katello-service status"
        echo
        exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

if [[ -z ${0} ]];then
	echo "Have to have an uteeg/etc/hosts entry"
	echo ""
	echo "And use the vmanme as parameter: ./daily_New_host.sh vmname"
	exit 1
fi

#if [[ -z ${0} ]]; [[ -z ${1} ]];then
#	VMNAME="test02"
#	IP="10.0.0.24"
#else
#	VMNAME="${0}"
#	IP="${1}"
#fi

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
LIFECYCLE=$(awk /"^${1}"/'{print $17}' "${inputfile}")
CONTENTVIEW=$(awk /"^${1}"/'{print $18}' "${inputfile}")

ssh ${GATEWAY} "grep -i ${IP} ${VMNAME}.${DOMAIN} ${VMNAME} /etc/hosts || echo ${IP} ${VMNAME}.${DOMAIN} ${VMNAME} >> /etc/hosts"

ssh ${GATEWAY} "systemctl stop libvirtd"
ssh ${GATEWAY} "systemctl stop dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "pkill libvirtd"
ssh ${GATEWAY} "pkill dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl start libvirtd"
ssh ${GATEWAY} "systemctl start dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl status libvirtd"
ssh ${GATEWAY} "systemctl status dnsmasq"

ssh ${GATEWAY} "virsh list --all | grep ${VMNAME} && virsh destroy ${VMNAME}.${DOMAIN}"
ssh ${GATEWAY} "virsh list --all | grep ${VMNAME} && virsh undefine ${VMNAME}.${DOMAIN}"
ssh ${GATEWAY} "rm -fv /var/lib/libvirt/images/${VMNAME}*"
ssh ${GATEWAY} "rm -fv /tmp/${VMNAME}*"
#ssh ${GATEWAY} "rm -f /var/lib/libvirt/images/"${VMNAME}".data.qcow2"
hammer host delete --name="${VMNAME}.${DOMAIN}"

ssh ${GATEWAY} "systemctl stop libvirtd"
ssh ${GATEWAY} "systemctl stop dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "pkill libvirtd"
ssh ${GATEWAY} "pkill dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl start libvirtd"
ssh ${GATEWAY} "systemctl start dnsmasq"
ssh ${GATEWAY} "sleep 5"
ssh ${GATEWAY} "systemctl status libvirtd"
ssh ${GATEWAY} "systemctl status dnsmasq"

#hammer host create \
#--name="${VMNAME}" \
#--hostgroup=HG_Infra_1_Dev_CV_RHEL7_Core_ORG_redhat_LOC_laptop \
#--organization=redhat \
#--location=laptop \
#--interface="primary=true,compute_type=network,compute_network=laptoplab,ip=${IP}" \
#--subnet="10.0.0.0/24" \
#--volume="capacity=10G,format_type=qcow2" \
#--compute-attributes="cpus=1,memory=1024"
#--compute-resource=Libvirt_CR

hammer host create --name "${VMNAME}" --organization "redhat" \
--location "laptop" --hostgroup "HG_${LIFECYCLE}_${CONTENTVIEW}_ORG_${ORG}_LOC_${LOC}" \
--compute-resource "Libvirt_CR" \
--interface "managed=true,primary=true,provision=true,compute_type=network,compute_network=laptoplab,ip=${IP}" \
--subnet="10.0.0.0/24" \
--compute-attributes="cpus=1,memory=1073741824" \
--volume="pool_name=default,capacity=20G,format_type=qcow2"

# bootdisk host pulls down the boot media from satellite
#hammer bootdisk host --force --host=${VMNAME}.${DOMAIN}
hammer bootdisk host --host=${VMNAME}.${DOMAIN}
scp ${VMNAME}.${DOMAIN}.iso ${GATEWAY}:/var/lib/libvirt/images/
# this is how to inline edit a libvirt vm to add cdrom
ssh ${GATEWAY} "virsh dumpxml ${VMNAME}.${DOMAIN} > /tmp/${VMNAME}.${DOMAIN}.xml"
ssh ${GATEWAY} "sed -i '0,/network/s//cdrom/' /tmp/${VMNAME}.${DOMAIN}.xml"
#ssh ${GATEWAY} sed -i /dev=\'network\'/a \ \ \ \ <boot dev=\'cdrom\'\ \/> /tmp/${VMNAME}.${DOMAIN}.xml
# search for </disk> and insert
cat << EOH > /root/cdrom.txt
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hda' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
EOH
scp /root/cdrom.txt ${GATEWAY}:/var/lib/libvirt/images/
ssh ${GATEWAY} "sed -iE '/\/disk\>/r /var/lib/libvirt/images/cdrom.txt' /tmp/${VMNAME}.${DOMAIN}.xml"
ssh ${GATEWAY} "/bin/virsh define /tmp/${VMNAME}.${DOMAIN}.xml"
ssh ${GATEWAY} "/bin/virsh start ${VMNAME}.${DOMAIN}"
ssh ${GATEWAY} "/bin/virsh attach-disk ${VMNAME}.${DOMAIN} /var/lib/libvirt/images/${VMNAME}.${DOMAIN}.iso hda --type cdrom --mode readonly"
ssh ${GATEWAY} "/bin/virsh reset ${VMNAME}.${DOMAIN}"

#all this silly restarting is messing up virt-who
systemctl restart virt-who

echo "###INFO: Finished $0"
echo "###INFO: $(date)"

#yum install libvirt-client

#comment block of text in bash shell
: <<'END'

[root@sat62 bin]# virsh --connect qemu+ssh://root@10.0.0.1/system list
 Id    Name                           State
----------------------------------------------------
 1     checkmk-admin                  running
 2     virt-host                      running
 3     test02.prayther.org            running
 4     sat62                          running
 5     CFME5.8                        running
 6     ans0tower                      running
 7     ans0node10infra0dev0exop       running
 8     ans0admin0infra0dev0exop       running
 10    sat0stig.prayther.org          running
 11    sat0otrs.prayther.org          running

[root@sat62 bin]# virsh --connect qemu+ssh://root@10.0.0.1/system --help

virsh [options]... [<command_string>]
virsh [options]... <command> [args...]

  options:
    -c | --connect=URI      hypervisor connection URI
    -d | --debug=NUM        debug level [0-4]
    -e | --escape <char>    set escape sequence for console
    -h | --help             this help
    -k | --keepalive-interval=NUM
                            keepalive interval in seconds, 0 for disable
    -K | --keepalive-count=NUM
                            number of possible missed keepalive messages
    -l | --log=FILE         output logging to file
    -q | --quiet            quiet mode
    -r | --readonly         connect readonly
    -t | --timing           print timing information
    -v                      short version
    -V                      long version
         --version[=TYPE]   version, TYPE is short or long (default short)
  commands (non interactive mode):

 Domain Management (help keyword 'domain')
    attach-device                  attach device from an XML file
    attach-disk                    attach disk device
    attach-interface               attach network interface
    autostart                      autostart a domain
    blkdeviotune                   Set or query a block device I/O tuning parameters.
    blkiotune                      Get or set blkio parameters
    blockcommit                    Start a block commit operation.
    blockcopy                      Start a block copy operation.
    blockjob                       Manage active block operations
    blockpull                      Populate a disk from its backing image.
    blockresize                    Resize block device of domain.
    change-media                   Change media of CD or floppy drive
    console                        connect to the guest console
    cpu-baseline                   compute baseline CPU
    cpu-compare                    compare host CPU with a CPU described by an XML file
    cpu-stats                      show domain cpu statistics
    create                         create a domain from an XML file
    define                         define (but don't start) a domain from an XML file
    desc                           show or set domain's description or title
    destroy                        destroy (stop) a domain
    detach-device                  detach device from an XML file
    detach-disk                    detach disk device
    detach-interface               detach network interface
    domdisplay                     domain display connection URI
    domfsfreeze                    Freeze domain's mounted filesystems.
    domfsthaw                      Thaw domain's mounted filesystems.
    domfsinfo                      Get information of domain's mounted filesystems.
    domfstrim                      Invoke fstrim on domain's mounted filesystems.
    domhostname                    print the domain's hostname
    domid                          convert a domain name or UUID to domain id
    domif-setlink                  set link state of a virtual interface
    domiftune                      get/set parameters of a virtual interface
    domjobabort                    abort active domain job
    domjobinfo                     domain job information
    domname                        convert a domain id or UUID to domain name
    domrename                      rename a domain
    dompmsuspend                   suspend a domain gracefully using power management functions
    dompmwakeup                    wakeup a domain from pmsuspended state
    domuuid                        convert a domain name or id to domain UUID
    domxml-from-native             Convert native config to domain XML
    domxml-to-native               Convert domain XML to native config
    dump                           dump the core of a domain to a file for analysis
    dumpxml                        domain information in XML
    edit                           edit XML configuration for a domain
    event                          Domain Events
    inject-nmi                     Inject NMI to the guest
    iothreadinfo                   view domain IOThreads
    iothreadpin                    control domain IOThread affinity
    iothreadadd                    add an IOThread to the guest domain
    iothreaddel                    delete an IOThread from the guest domain
    send-key                       Send keycodes to the guest
    send-process-signal            Send signals to processes
    lxc-enter-namespace            LXC Guest Enter Namespace
    managedsave                    managed save of a domain state
    managedsave-remove             Remove managed save of a domain
    memtune                        Get or set memory parameters
    perf                           Get or set perf event
    metadata                       show or set domain's custom XML metadata
    migrate                        migrate domain to another host
    migrate-setmaxdowntime         set maximum tolerable downtime
    migrate-compcache              get/set compression cache size
    migrate-setspeed               Set the maximum migration bandwidth
    migrate-getspeed               Get the maximum migration bandwidth
    migrate-postcopy               Switch running migration from pre-copy to post-copy
    numatune                       Get or set numa parameters
    qemu-attach                    QEMU Attach
    qemu-monitor-command           QEMU Monitor Command
    qemu-monitor-event             QEMU Monitor Events
    qemu-agent-command             QEMU Guest Agent Command
    reboot                         reboot a domain
    reset                          reset a domain
    restore                        restore a domain from a saved state in a file
    resume                         resume a domain
    save                           save a domain state to a file
    save-image-define              redefine the XML for a domain's saved state file
    save-image-dumpxml             saved state domain information in XML
    save-image-edit                edit XML for a domain's saved state file
    schedinfo                      show/set scheduler parameters
    screenshot                     take a screenshot of a current domain console and store it into a file
    set-user-password              set the user password inside the domain
    setmaxmem                      change maximum memory limit
    setmem                         change memory allocation
    setvcpus                       change number of virtual CPUs
    shutdown                       gracefully shutdown a domain
    start                          start a (previously defined) inactive domain
    suspend                        suspend a domain
    ttyconsole                     tty console
    undefine                       undefine a domain
    update-device                  update device from an XML file
    vcpucount                      domain vcpu counts
    vcpuinfo                       detailed domain vcpu information
    vcpupin                        control or query domain vcpu affinity
    emulatorpin                    control or query domain emulator affinity
    vncdisplay                     vnc display
    guestvcpus                     query or modify state of vcpu in the guest (via agent)
    setvcpu                        attach/detach vcpu or groups of threads
    domblkthreshold                set the threshold for block-threshold event for a given block device or it's backing chain element

 Domain Monitoring (help keyword 'monitor')
    domblkerror                    Show errors on block devices
    domblkinfo                     domain block device size information
    domblklist                     list all domain blocks
    domblkstat                     get device block stats for a domain
    domcontrol                     domain control interface state
    domif-getlink                  get link state of a virtual interface
    domifaddr                      Get network interfaces' addresses for a running domain
    domiflist                      list all domain virtual interfaces
    domifstat                      get network interface stats for a domain
    dominfo                        domain information
    dommemstat                     get memory statistics for a domain
    domstate                       domain state
    domstats                       get statistics about one or multiple domains
    domtime                        domain time
    list                           list domains

 Host and Hypervisor (help keyword 'host')
    allocpages                     Manipulate pages pool size
    capabilities                   capabilities
    cpu-models                     CPU models
    domcapabilities                domain capabilities
    freecell                       NUMA free memory
    freepages                      NUMA free pages
    hostname                       print the hypervisor hostname
    maxvcpus                       connection vcpu maximum
    node-memory-tune               Get or set node memory parameters
    nodecpumap                     node cpu map
    nodecpustats                   Prints cpu stats of the node.
    nodeinfo                       node information
    nodememstats                   Prints memory stats of the node.
    nodesuspend                    suspend the host node for a given time duration
    sysinfo                        print the hypervisor sysinfo
    uri                            print the hypervisor canonical URI
    version                        show version

 Interface (help keyword 'interface')
    iface-begin                    create a snapshot of current interfaces settings, which can be later committed (iface-commit) or restored (iface-rollback)
    iface-bridge                   create a bridge device and attach an existing network device to it
    iface-commit                   commit changes made since iface-begin and free restore point
    iface-define                   define an inactive persistent physical host interface or modify an existing persistent one from an XML file
    iface-destroy                  destroy a physical host interface (disable it / "if-down")
    iface-dumpxml                  interface information in XML
    iface-edit                     edit XML configuration for a physical host interface
    iface-list                     list physical host interfaces
    iface-mac                      convert an interface name to interface MAC address
    iface-name                     convert an interface MAC address to interface name
    iface-rollback                 rollback to previous saved configuration created via iface-begin
    iface-start                    start a physical host interface (enable it / "if-up")
    iface-unbridge                 undefine a bridge device after detaching its slave device
    iface-undefine                 undefine a physical host interface (remove it from configuration)

 Network Filter (help keyword 'filter')
    nwfilter-define                define or update a network filter from an XML file
    nwfilter-dumpxml               network filter information in XML
    nwfilter-edit                  edit XML configuration for a network filter
    nwfilter-list                  list network filters
    nwfilter-undefine              undefine a network filter

 Networking (help keyword 'network')
    net-autostart                  autostart a network
    net-create                     create a network from an XML file
    net-define                     define an inactive persistent virtual network or modify an existing persistent one from an XML file
    net-destroy                    destroy (stop) a network
    net-dhcp-leases                print lease info for a given network
    net-dumpxml                    network information in XML
    net-edit                       edit XML configuration for a network
    net-event                      Network Events
    net-info                       network information
    net-list                       list networks
    net-name                       convert a network UUID to network name
    net-start                      start a (previously defined) inactive network
    net-undefine                   undefine a persistent network
    net-update                     update parts of an existing network's configuration
    net-uuid                       convert a network name to network UUID

 Node Device (help keyword 'nodedev')
    nodedev-create                 create a device defined by an XML file on the node
    nodedev-destroy                destroy (stop) a device on the node
    nodedev-detach                 detach node device from its device driver
    nodedev-dumpxml                node device details in XML
    nodedev-list                   enumerate devices on this host
    nodedev-reattach               reattach node device to its device driver
    nodedev-reset                  reset node device
    nodedev-event                  Node Device Events

 Secret (help keyword 'secret')
    secret-define                  define or modify a secret from an XML file
    secret-dumpxml                 secret attributes in XML
    secret-event                   Secret Events
    secret-get-value               Output a secret value
    secret-list                    list secrets
    secret-set-value               set a secret value
    secret-undefine                undefine a secret

 Snapshot (help keyword 'snapshot')
    snapshot-create                Create a snapshot from XML
    snapshot-create-as             Create a snapshot from a set of args
    snapshot-current               Get or set the current snapshot
    snapshot-delete                Delete a domain snapshot
    snapshot-dumpxml               Dump XML for a domain snapshot
    snapshot-edit                  edit XML for a snapshot
    snapshot-info                  snapshot information
    snapshot-list                  List snapshots for a domain
    snapshot-parent                Get the name of the parent of a snapshot
    snapshot-revert                Revert a domain to a snapshot

 Storage Pool (help keyword 'pool')
    find-storage-pool-sources-as   find potential storage pool sources
    find-storage-pool-sources      discover potential storage pool sources
    pool-autostart                 autostart a pool
    pool-build                     build a pool
    pool-create-as                 create a pool from a set of args
    pool-create                    create a pool from an XML file
    pool-define-as                 define a pool from a set of args
    pool-define                    define an inactive persistent storage pool or modify an existing persistent one from an XML file
    pool-delete                    delete a pool
    pool-destroy                   destroy (stop) a pool
    pool-dumpxml                   pool information in XML
    pool-edit                      edit XML configuration for a storage pool
    pool-info                      storage pool information
    pool-list                      list pools
    pool-name                      convert a pool UUID to pool name
    pool-refresh                   refresh a pool
    pool-start                     start a (previously defined) inactive pool
    pool-undefine                  undefine an inactive pool
    pool-uuid                      convert a pool name to pool UUID
    pool-event                     Storage Pool Events

 Storage Volume (help keyword 'volume')
    vol-clone                      clone a volume.
    vol-create-as                  create a volume from a set of args
    vol-create                     create a vol from an XML file
    vol-create-from                create a vol, using another volume as input
    vol-delete                     delete a vol
    vol-download                   download volume contents to a file
    vol-dumpxml                    vol information in XML
    vol-info                       storage vol information
    vol-key                        returns the volume key for a given volume name or path
    vol-list                       list vols
    vol-name                       returns the volume name for a given volume key or path
    vol-path                       returns the volume path for a given volume name or key
    vol-pool                       returns the storage pool for a given volume key or path
    vol-resize                     resize a vol
    vol-upload                     upload file contents to a volume
    vol-wipe                       wipe a vol

 Virsh itself (help keyword 'virsh')
    cd                             change the current directory
    echo                           echo arguments
    exit                           quit this interactive terminal
    help                           print help
    pwd                            print the current directory
    quit                           quit this interactive terminal
    connect                        (re)connect to hypervisor


  (specify help <group> for details about the commands in the group)

  (specify help <command> for details about the command)
END
